import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/logo.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'home_screen.dart';
import 'intro_screen.dart';

/// 랜딩 (7a-2) — 로그인의 주 진입점. 인트로 없이도 이해하고 바로 시작.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _summaries = [
    '한가한 친구가 먼저 보여요',
    '거절은 아무에게도 안 보여요',
    '시간 지나면 알아서 꺼져요',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 콘텐츠 영역 (flex:1, 세로 중앙, 좌우 24, gap 32)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.screenContent),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => _openDevLogin(context),
                      child: const TukLogo(size: 80),
                    ),
                    const SizedBox(height: AppSpace.x32),
                    Text('시간 비었을 때\n툭 던지면 끝', style: AppText.display),
                    const SizedBox(height: AppSpace.x12),
                    Text(
                      '단톡방에 묻지 않아도 돼요. 지금 한가한 절친만 보고, 한 탭으로 부르세요.',
                      style: AppText.body.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppSpace.x32),
                    for (final s in _summaries) ...[
                      SummaryCard(s),
                      if (s != _summaries.last)
                        const SizedBox(height: AppSpace.x10),
                    ],
                  ],
                ),
              ),
            ),
            // 버튼 영역 (좌우 20, gap 12)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screenButtons, 0, AppSpace.screenButtons, AppSpace.x8),
              child: Column(
                children: [
                  _KakaoLoginButton(
                    label: '카카오로 3초 만에 시작',
                    onDone: () => _goHome(context),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  _BrowseButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IntroScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x4),
                  const _TermsNotice(),
                  const SizedBox(height: AppSpace.x8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// 숨은 dev 경로 — 로고 롱프레스로 임의 dev 아이디 로그인(멀티계정 테스트용).
  Future<void> _openDevLogin(BuildContext context) async {
    final controller = TextEditingController(text: 'tuk_dev');
    final id = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('개발용 로그인'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'dev 아이디(아무 문자열)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('로그인'),
          ),
        ],
      ),
    );
    if (id == null || id.isEmpty || !context.mounted) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(provider: 'dev', token: id);
    if (!context.mounted) return;
    if (ok) {
      _goHome(context);
    } else {
      showTukToast(context, auth.error ?? '로그인에 실패했어요.');
    }
  }
}

/// 카카오 로그인 버튼 — 카카오톡(설치 시) 또는 카카오계정으로 로그인.
class _KakaoLoginButton extends StatelessWidget {
  const _KakaoLoginButton({required this.label, required this.onDone});

  final String label;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return PillButton.kakao(
      label,
      loading: auth.busy,
      leading: const _KakaoMark(),
      onPressed: () async {
        final ok = await auth.loginWithKakao();
        if (!context.mounted) return;
        if (ok) {
          onDone();
        } else if (auth.error != null) {
          // error == null 이면 사용자가 취소한 것 — 아무 말도 하지 않는다
          showTukToast(context, auth.error!);
        }
      },
    );
  }
}

/// 카카오 로고 자리표시자 22×22 (공식 에셋으로 교체 예정).
class _KakaoMark extends StatelessWidget {
  const _KakaoMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Icon(Icons.chat_bubble_rounded, size: 20, color: Color(0xFF3C1E1E)),
    );
  }
}

/// "툭이 뭔가요? 30초만 둘러보기" — 배경 없는 밑줄 텍스트, 높이 52.
class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.secondaryButton,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            '툭이 뭔가요? 30초만 둘러보기',
            style: AppText.label15.copyWith(
              color: AppColors.textSub,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.border,
              decorationThickness: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 약관 안내 — 중앙, 이용약관/개인정보 처리방침만 밑줄·탭 가능.
class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    final link = AppText.caption12.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.border,
    );
    return Text.rich(
      TextSpan(
        style: AppText.caption12,
        children: [
          const TextSpan(text: '계속하면 '),
          TextSpan(text: '이용약관', style: link),
          const TextSpan(text: '·'),
          TextSpan(text: '개인정보 처리방침', style: link),
          const TextSpan(text: '에 동의합니다'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
