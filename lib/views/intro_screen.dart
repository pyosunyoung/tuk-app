import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';

/// 인트로 5컷 (6b) — 다음 단계(task 11)에서 본구현.
/// 지금은 랜딩 "둘러보기" 네비게이션 확인용 최소 stub.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('인트로 5컷 (곧 구현)', style: AppText.title20),
              const SizedBox(height: AppSpace.x16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('랜딩으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
