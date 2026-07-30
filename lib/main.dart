import 'package:flutter/material.dart';

import 'core/theme.dart';

void main() => runApp(const BungaeApp());

/// 앱 루트. 지금은 기초 세팅 단계라 플레이스홀더 화면만 보여준다.
/// 로그인/홈 등 기능은 이후 커밋에서 하나씩 붙는다.
class BungaeApp extends StatelessWidget {
  const BungaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '번개',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _SetupPlaceholder(),
    );
  }
}

class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text('번개',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('기초 세팅 완료 — 곧 기능이 붙습니다',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
