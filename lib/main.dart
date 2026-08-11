import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/friend_repository.dart';
import 'repositories/presence_repository.dart';
import 'services/api_client.dart';
import 'services/stomp_service.dart';
import 'services/token_storage.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/presence_view_model.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 의존성 조립 ----------------------------------------------------
  final tokens = TokenStorage();
  final stomp = StompService();

  late final AuthViewModel authVM;
  final api = ApiClient(
    tokens,
    onSessionExpired: () async => authVM.onSessionExpired(),
  );
  authVM = AuthViewModel(tokens: tokens, auth: AuthRepository(api));

  final presenceVM = PresenceViewModel(
    presence: PresenceRepository(api),
    friend: FriendRepository(api),
    stomp: stomp,
    tokens: tokens,
  );

  // 인증 상태 → 실시간(프레즌스) lifecycle. 상태가 실제로 바뀔 때만.
  AuthStatus? prev;
  authVM.addListener(() {
    final s = authVM.status;
    if (s == prev) return;
    prev = s;
    if (s == AuthStatus.loggedIn) {
      presenceVM.start();
    } else if (s == AuthStatus.loggedOut) {
      presenceVM.stop();
    }
  });

  runApp(TukApp(authVM: authVM, presenceVM: presenceVM));
}

class TukApp extends StatelessWidget {
  const TukApp({super.key, required this.authVM, required this.presenceVM});

  final AuthViewModel authVM;
  final PresenceViewModel presenceVM;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authVM),
        ChangeNotifierProvider.value(value: presenceVM),
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
