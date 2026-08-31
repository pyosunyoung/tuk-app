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
import 'services/stomp_service.dart';
import 'services/token_storage.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/flash_view_model.dart';
import 'viewmodels/friend_view_model.dart';
import 'viewmodels/presence_view_model.dart';
import 'views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    tokens: tokens,
  );
  final friendVM = FriendViewModel(friendRepo);
  final flashVM = FlashViewModel(flash: FlashRepository(api), stomp: stomp);

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
    } else if (s == AuthStatus.loggedOut) {
      presenceVM.stop();
      friendVM.reset();
      flashVM.reset();
    }
  });

  runApp(TukApp(
    authVM: authVM,
    presenceVM: presenceVM,
    friendVM: friendVM,
    flashVM: flashVM,
  ));
}

class TukApp extends StatelessWidget {
  const TukApp({
    super.key,
    required this.authVM,
    required this.presenceVM,
    required this.friendVM,
    required this.flashVM,
  });

  final AuthViewModel authVM;
  final PresenceViewModel presenceVM;
  final FriendViewModel friendVM;
  final FlashViewModel flashVM;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authVM),
        ChangeNotifierProvider.value(value: presenceVM),
        ChangeNotifierProvider.value(value: friendVM),
        ChangeNotifierProvider.value(value: flashVM),
      ],
      child: MaterialApp(
        title: '툭',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
