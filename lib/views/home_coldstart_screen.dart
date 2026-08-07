import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/logo.dart';
import 'landing_screen.dart';

/// 홈 콜드스타트 (1b) — 다음 단계(task 12)에서 본구현.
/// 지금은 로그인 성공 착지점 + 로그아웃(랜딩 복귀)만.
class HomeColdstartScreen extends StatelessWidget {
  const HomeColdstartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TukLogo(size: 96, variant: TukLogoVariant.light),
              const SizedBox(height: AppSpace.x20),
              Text('로그인 성공 — 홈 콜드스타트', style: AppText.title20),
              const SizedBox(height: AppSpace.x8),
              Text('이 화면은 다음 단계에서 디자인대로 구현됩니다',
                  style: AppText.caption13),
              const SizedBox(height: AppSpace.x24),
              TextButton(
                onPressed: () async {
                  final auth = context.read<AuthViewModel>();
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (route) => false,
                  );
                },
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
