import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 의존성 조립 (로그인 기능 범위) ---------------------------------
  final tokens = TokenStorage();

  late final AuthViewModel authVM;
  final api = ApiClient(
    tokens,
    onSessionExpired: () async => authVM.onSessionExpired(),
  );
  authVM = AuthViewModel(
    tokens: tokens,
    auth: AuthRepository(api),
  );

  runApp(TukApp(authVM: authVM));
}

class TukApp extends StatelessWidget {
  const TukApp({super.key, required this.authVM});

  final AuthViewModel authVM;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authVM,
      child: MaterialApp(
        title: '툭',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
