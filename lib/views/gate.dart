import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import 'home_shell.dart';
import 'login_view.dart';

/// 앱 진입점 — 저장된 세션을 확인해 로그인/홈으로 분기.
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthViewModel>().status;
    return switch (status) {
      AuthStatus.unknown => const _Splash(),
      AuthStatus.loggedOut => const LoginView(),
      AuthStatus.loggedIn => const HomeShell(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚡', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
