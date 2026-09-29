import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'models/realtime_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/flash_repository.dart';
import 'repositories/place_repository.dart';
import 'repositories/friend_repository.dart';
import 'repositories/presence_repository.dart';
import 'repositories/user_repository.dart';
import 'services/api_client.dart';
import 'services/deep_link_service.dart';
import 'services/push_service.dart';
import 'services/stomp_service.dart';
import 'services/token_storage.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/flash_view_model.dart';
import 'viewmodels/friend_view_model.dart';
import 'viewmodels/presence_view_model.dart';
import 'views/friends_screen.dart';
import 'views/received_flashes_screen.dart';
import 'views/room_screen.dart';
import 'views/splash_screen.dart';
import 'widgets/toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FCM. 키(google-services.json)가 없으면 초기화가 실패하는데, 그래도 앱은 떠야 한다.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('[tuk] Firebase 초기화 실패 — 푸시 없이 계속: $e');
  }

  // 카카오 SDK — 키가 없으면 초기화를 건너뛴다(다른 기능은 그대로 동작).
  if (KakaoConfig.isConfigured) {
    await KakaoSdk.init(nativeAppKey: KakaoConfig.nativeAppKey);
  } else {
    debugPrint('[tuk] 카카오 네이티브 앱 키 미설정 — 카카오 로그인 비활성 (KakaoConfig 참고)');
  }

  // 카카오톡 공유 카드로 켜졌으면 그 링크를 먼저 받아 둔다(처리는 로그인 후 홈에서)
  final deepLinks = DeepLinkService();
  await deepLinks.start();

  // --- 의존성 조립 ----------------------------------------------------
  final tokens = TokenStorage();
  final stomp = StompService();

  late final AuthViewModel authVM;
  final api = ApiClient(
    tokens,
    onSessionExpired: () async => authVM.onSessionExpired(),
  );
  authVM = AuthViewModel(
    tokens: tokens,
    auth: AuthRepository(api),
    user: UserRepository(api),
  );

  final friendRepo = FriendRepository(api);
  final presenceVM = PresenceViewModel(
    presence: PresenceRepository(api),
    friend: friendRepo,
    stomp: stomp,
    accessToken: api.validAccessToken,
  );
  final friendVM = FriendViewModel(friendRepo);
  final flashVM = FlashViewModel(
    flash: FlashRepository(api),
    place: PlaceRepository(api),
    stomp: stomp,
  );
  final pushVM = PushService(DeviceTokenRepository(api));

  // 인증 상태 → 실시간(프레즌스)·친구 lifecycle. 상태가 실제로 바뀔 때만.
  AuthStatus? prev;
  authVM.addListener(() {
    final s = authVM.status;
    if (s == prev) return;
    prev = s;
    if (s == AuthStatus.loggedIn) {
      presenceVM.start();
      friendVM.load();
      flashVM.load();
      pushVM.start(); // 기기토큰은 로그인 후에 등록한다
    } else if (s == AuthStatus.loggedOut) {
      presenceVM.stop();
      friendVM.reset();
      flashVM.reset();
      pushVM.stop(); // 로그아웃한 기기로 남의 알림이 가면 안 된다
    }
  });

  runApp(TukApp(
    authVM: authVM,
    presenceVM: presenceVM,
    friendVM: friendVM,
    flashVM: flashVM,
    push: pushVM,
    deepLinks: deepLinks,
  ));
}

class TukApp extends StatefulWidget {
  const TukApp({
    super.key,
    required this.authVM,
    required this.presenceVM,
    required this.friendVM,
    required this.flashVM,
    required this.push,
    required this.deepLinks,
  });

  final AuthViewModel authVM;
  final PresenceViewModel presenceVM;
  final FriendViewModel friendVM;
  final FlashViewModel flashVM;
  final PushService push;
  final DeepLinkService deepLinks;

  @override
  State<TukApp> createState() => _TukAppState();
}

class _TukAppState extends State<TukApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _flashSub;

  @override
  void initState() {
    super.initState();
    widget.push.tapped.addListener(_onPushTapped);
    widget.push.friendsChanged.addListener(_onFriendsChanged);
    _flashSub = widget.flashVM.events.listen(_onFlashEvent);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.push.tapped.removeListener(_onPushTapped);
    widget.push.friendsChanged.removeListener(_onFriendsChanged);
    _flashSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 백그라운드에선 실시간 연결을 끊어 서버가 FCM 으로 보내게 하고, 돌아오면 다시 붙인다.
  /// `inactive`(알림창 내림·앱 전환 중)는 잠깐이라 무시 — `paused` 에서만 끊는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.presenceVM.pauseRealtime();
    } else if (state == AppLifecycleState.resumed) {
      if (!widget.presenceVM.resumeRealtime()) return;
      // 끊겨 있던 사이 온 툭·합류·장소 변경·친구 신청은 WebSocket 으로 못 받았다 — 다시 불러온다
      widget.flashVM.load();
      widget.friendVM.load();
    }
  }

  /// 앱을 보고 있는데 다른 멤버가 장소·시간을 바꿨다 — 접속 중이라 푸시 대신 WebSocket 으로 온다.
  /// 그 모임방을 보고 있으면 방이 직접 알리므로 여기선 건너뛴다(토스트 중복 방지).
  void _onFlashEvent(FlashPushEvent e) {
    if (!e.isPlanUpdated || RoomScreen.isOpen(e.flashId)) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx != null) showTukToast(ctx, planUpdateText(e));
  }

  /// 알림을 탭해서 들어온 경우: 친구 알림은 친구 화면, 합류·장소·시간은 그 모임방, 나머지는 받은 툭.
  void _onPushTapped() {
    final data = widget.push.tapped.value;
    if (data == null) return; // 처리 후 null 로 되돌릴 때도 리스너가 한 번 더 불린다
    widget.push.tapped.value = null;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] ?? '';
    final flashId = int.tryParse(data['flashId'] ?? '');

    if (type.startsWith('FRIEND_')) {
      widget.friendVM.load(); // 신청/수락이 화면에 바로 반영되게
      navigator.push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
    } else if (_roomTypes.contains(type) && flashId != null) {
      navigator.push(MaterialPageRoute(builder: (_) => RoomScreen(flashId: flashId)));
    } else {
      navigator.push(MaterialPageRoute(builder: (_) => const ReceivedFlashesScreen()));
    }
  }

  static const _roomTypes = {'MEMBER_JOINED', 'PLACE_UPDATED', 'MEET_AT_UPDATED'};

  /// 앱이 떠 있는 동안 친구 알림이 오면 배지를 바로 갱신한다.
  void _onFriendsChanged() => widget.friendVM.load();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authVM),
        ChangeNotifierProvider.value(value: widget.presenceVM),
        ChangeNotifierProvider.value(value: widget.friendVM),
        ChangeNotifierProvider.value(value: widget.flashVM),
        Provider.value(value: widget.deepLinks),
      ],
      child: MaterialApp(
        title: '툭',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
