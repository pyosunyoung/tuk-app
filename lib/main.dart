import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/flash_repository.dart';
import 'repositories/friend_repository.dart';
import 'repositories/presence_repository.dart';
import 'repositories/user_repository.dart';
import 'services/api_client.dart';
import 'services/push_service.dart';
import 'services/stomp_service.dart';
import 'services/token_storage.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/flash_view_model.dart';
import 'viewmodels/friend_view_model.dart';
import 'viewmodels/presence_view_model.dart';
import 'views/received_flashes_screen.dart';
import 'views/room_screen.dart';
import 'views/splash_screen.dart';

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
  final flashVM = FlashViewModel(flash: FlashRepository(api), stomp: stomp);
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
  });

  final AuthViewModel authVM;
  final PresenceViewModel presenceVM;
  final FriendViewModel friendVM;
  final FlashViewModel flashVM;
  final PushService push;

  @override
  State<TukApp> createState() => _TukAppState();
}

class _TukAppState extends State<TukApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.push.tapped.addListener(_onPushTapped);
  }

  @override
  void dispose() {
    widget.push.tapped.removeListener(_onPushTapped);
    super.dispose();
  }

  /// 알림을 탭해서 들어온 경우: 새 번개는 목록으로, 합류 알림은 그 모임방으로.
  void _onPushTapped() {
    final data = widget.push.tapped.value;
    if (data == null) return; // 처리 후 null 로 되돌릴 때도 리스너가 한 번 더 불린다
    widget.push.tapped.value = null;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final flashId = int.tryParse(data['flashId'] ?? '');
    if (data['type'] == 'MEMBER_JOINED' && flashId != null) {
      navigator.push(MaterialPageRoute(builder: (_) => RoomScreen(flashId: flashId)));
    } else {
      navigator.push(MaterialPageRoute(builder: (_) => const ReceivedFlashesScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authVM),
        ChangeNotifierProvider.value(value: widget.presenceVM),
        ChangeNotifierProvider.value(value: widget.friendVM),
        ChangeNotifierProvider.value(value: widget.flashVM),
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
