import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _devName = TextEditingController(text: 'tester');

  @override
  void dispose() {
    _devName.dispose();
    super.dispose();
  }

  Future<void> _devLogin() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(provider: 'dev', token: _devName.text.trim());
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('⚡', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('번개',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('지금 볼래? 절친에게 번개 띄우기',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.outline)),
              const Spacer(),

              // 개발용 dev 로그인 — provider: "dev"
              TextField(
                controller: _devName,
                decoration: const InputDecoration(
                  labelText: '개발용 로그인 아이디',
                  helperText: 'dev 프로필: 아무 문자열이나 계정이 됩니다',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: auth.busy ? null : _devLogin,
                child: auth.busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('개발용 로그인'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는',
                      style: TextStyle(color: theme.colorScheme.outline)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: auth.busy
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('카카오 로그인은 네이티브 SDK 연동 후 활성화됩니다.'),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Text('💬'),
                label: const Text('카카오로 시작하기'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
