import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../widgets/logo.dart';
import '../viewmodels/auth_view_model.dart';
import 'home_screen.dart';
import 'landing_screen.dart';

/// 스플래시 (7a-1) — 코랄 전면, 로고 등장(0.92→1, 320ms) 후 ~1s 만에 분기.
/// 로그인 상태면 홈으로 직행, 아니면 랜딩으로.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _shown = true);
      _boot();
    });
  }

  Future<void> _boot() async {
    final auth = context.read<AuthViewModel>();
    // 브랜드 노출 최소 시간 + 세션 확인을 동시에.
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1100)),
      auth.bootstrap(),
    ]);
    if (!mounted) return;
    final loggedIn = auth.status == AuthStatus.loggedIn;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => loggedIn ? const HomeScreen() : const LandingScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _shown ? 1 : 0.92,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TukLogo(size: 96, variant: TukLogoVariant.splashTile),
                const SizedBox(height: AppSpace.x20),
                Text(
                  '지금 볼래?',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
