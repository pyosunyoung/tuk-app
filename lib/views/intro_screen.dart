import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/logo.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'home_screen.dart';

/// 인트로 5컷 (6b) — 왜 필요한지(상황) → 어떻게 해결하는지(기능).
/// 좌우 스와이프 + "다음" 버튼. 마지막 컷에서 카카오(dev) 로그인.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _cutCount = 5;
  static const _slideCurve = Cubic(0.32, 0.72, 0, 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.animateToPage(
      _index + 1,
      duration: const Duration(milliseconds: 260),
      curve: _slideCurve,
    );
  }

  Future<void> _startWithKakao() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(provider: 'dev', token: 'tuk_dev');
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      showTukToast(context, auth.error ?? '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _cutCount - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 건너뛰기 (마지막 컷은 자리만 유지, 높이 46)
            SizedBox(
              height: 46,
              child: isLast
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.x20, vertical: AppSpace.x12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text('건너뛰기',
                              style: AppText.label14
                                  .copyWith(color: AppColors.textSub)),
                        ),
                      ),
                    ),
            ),

            // 컷 콘텐츠
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Cut1(),
                  _Cut2(),
                  _Cut3(),
                  _Cut4(),
                  _Cut5(),
                ],
              ),
            ),

            // 하단: 인디케이터 + (다음 | 카카오)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x20, 0, AppSpace.x20, AppSpace.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: AppSpace.x20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _PageIndicator(count: _cutCount, active: _index),
                    ),
                  ),
                  if (isLast) ...[
                    PillButton.kakao(
                      '카카오로 시작하기',
                      loading: context.watch<AuthViewModel>().busy,
                      leading: const SizedBox(
                        width: 22,
                        height: 22,
                        child: Icon(Icons.chat_bubble_rounded,
                            size: 20, color: Color(0xFF3C1E1E)),
                      ),
                      onPressed: _startWithKakao,
                    ),
                    const SizedBox(height: AppSpace.x12),
                    Text('가입만으로는 아무에게도 알림이 가지 않아요',
                        textAlign: TextAlign.center, style: AppText.caption12),
                  ] else
                    PillButton.primary('다음', onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── 공통 골격

/// 컷 콘텐츠 — 세로 중앙 정렬, 좌우 24. 내용이 길면 스크롤.
class _CutBody extends StatelessWidget {
  const _CutBody({required this.children, this.center = false});

  final List<Widget> children;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.screenContent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// 헤드라인 + 본문 (gap 12).
class _Headline extends StatelessWidget {
  const _Headline(this.title, this.body, {this.center = false});

  final String title;
  final String body;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.display, textAlign: align),
        const SizedBox(height: AppSpace.x12),
        Text(body,
            style: AppText.body.copyWith(color: AppColors.textSub),
            textAlign: align),
      ],
    );
  }
}

/// 페이지 인디케이터 — 비활성 6×6, 활성 20×6, gap 6.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          if (i != count - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// 흰 카드 공통.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.x20),
    this.color = AppColors.surface,
    this.border = true,
    this.shadow,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool border;
  final List<BoxShadow>? shadow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: border ? Border.all(color: AppColors.border) : null,
          boxShadow: shadow,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 1

class _Cut1 extends StatelessWidget {
  const _Cut1();

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      children: [
        _Card(
          shadow: AppShadow.cardFloat,
          padding: const EdgeInsets.all(AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('단톡방 · 우리들',
                  style: AppText.caption13.copyWith(
                      color: AppColors.textSub, fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpace.x12),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: AppSpace.x12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Text('오늘 저녁에 누구 시간 돼?',
                        style: AppText.label15
                            .copyWith(fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.x4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('오후 6:12', style: AppText.caption12),
              ),
              const SizedBox(height: AppSpace.x12),
              _skeleton(0.56, const Color(0xFFF4F0EA)),
              const SizedBox(height: AppSpace.x8),
              _skeleton(0.38, const Color(0xFFF7F4EF)),
              const SizedBox(height: AppSpace.x12),
              Center(child: Text('…답장 없음', style: AppText.caption13)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '갑자기 시간이 비는 날',
          '약속이 취소됐거나 오늘 일정이 없을 때. 단톡방에 던지자니 읽씹이 무섭고, 개인톡은 거절시키는 것 같아 미안하죠.',
        ),
      ],
    );
  }

  Widget _skeleton(double widthFactor, Color color) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.xsmall),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────── 컷 2

class _Cut2 extends StatelessWidget {
  const _Cut2();

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      children: [
        Text.rich(
          TextSpan(
            style: AppText.title16,
            children: [
              const TextSpan(text: '지금 한가한 친구 '),
              TextSpan(
                  text: '3', style: const TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        const _FriendCard(initial: '민', name: '민수', activity: '술'),
        const SizedBox(height: AppSpace.x8),
        const _FriendCard(initial: '지', name: '지호', activity: '카페'),
        const SizedBox(height: AppSpace.x8),
        const Opacity(
          opacity: 0.6,
          child: _FriendCard(initial: '유', name: '유진', activity: '아무거나'),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '누가 한가한지\n먼저 보여요',
          '개인톡으로 하나하나 물어볼 필요 없어요. 지금 콜을 켜둔 친구만 목록에 떠요.',
        ),
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.initial,
    required this.name,
    required this.activity,
  });

  final String initial;
  final String name;
  final String activity;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16, vertical: AppSpace.x12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Text(initial,
                style: AppText.label15.copyWith(
                    color: AppColors.primaryPress,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpace.x12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name,
                      style: AppText.label15
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: AppSpace.x8),
                  _ActivityChip(activity),
                ],
              ),
              const SizedBox(height: AppSpace.x4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpace.x4),
                  Text('지금 가능',
                      style: AppText.caption12.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.xsmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: AppText.caption12.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 3

class _Cut3 extends StatelessWidget {
  const _Cut3();

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      children: [
        // 푸시 알림 카드
        _Card(
          border: false,
          shadow: const [
            BoxShadow(
                color: Color(0x142B2926),
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TukLogo(size: 36),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('툭',
                            style: AppText.caption13.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('지금', style: AppText.caption12),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('민수가 툭 던졌어요 · 술',
                        style: AppText.label14
                            .copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        // 수신 카드
        _Card(
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('지금 볼래? · 술',
                  style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpace.x12),
              Row(
                children: [
                  Expanded(
                    child: _MiniButton(
                      '나도',
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: _MiniButton('다음에', filled: false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x12),
              Center(
                child: Text("'다음에'는 상대에게 보이지 않아요",
                    style: AppText.caption12),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '툭 던지면 알림이 딱',
          '한 탭이면 절친들에게 바로 닿아요. 지나쳐도 보낸 사람에겐 아무것도 안 보여서 서로 부담이 없어요.',
        ),
      ],
    );
  }
}

/// 수신 카드용 작은 버튼(시연용, 비인터랙티브) — 높이 44 pill.
class _MiniButton extends StatelessWidget {
  const _MiniButton(this.label, {required this.filled});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: filled ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppText.label15.copyWith(
          color: filled ? Colors.white : AppColors.textSub,
          fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 4

class _Cut4 extends StatelessWidget {
  const _Cut4();

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      children: [
        // 켜짐
        _Card(
          shadow: AppShadow.cardFloat,
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpace.x8),
                        Text('지금 콜 켜짐 · 카페',
                            style: AppText.title16
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpace.x16, top: AppSpace.x4),
                      child: Text('1시간 32분 뒤 자동으로 꺼져요',
                          style: AppText.caption13),
                    ),
                  ],
                ),
              ),
              const _MiniToggle(on: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x10),
        // 전환 표시
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('↓',
                  style: AppText.title20.copyWith(
                      color: AppColors.textSub, fontWeight: FontWeight.w500)),
              const SizedBox(width: AppSpace.x8),
              Text('시간이 지나면',
                  style: AppText.caption13
                      .copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x10),
        // 꺼짐
        _Card(
          color: AppColors.background,
          opacity: 0.75,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.border, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpace.x8),
              Text('지금 콜 꺼짐',
                  style: AppText.title16.copyWith(
                      color: AppColors.textSub, fontWeight: FontWeight.w500)),
              const Spacer(),
              const _MiniToggle(on: false),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '그리고 알아서 꺼져요',
          '지금 콜도 번개도 시간이 지나면 사라져요. 끄는 걸 잊어도 부담이 남지 않아요.',
        ),
      ],
    );
  }
}

/// 시각용 토글 (비인터랙티브).
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 5

class _Cut5 extends StatelessWidget {
  const _Cut5();

  static const _summaries = [
    '한가한 친구가 먼저 보여요',
    '거절은 아무에게도 안 보여요',
    '시간 지나면 알아서 꺼져요',
  ];

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      center: true,
      children: [
        const TukLogo(size: 72),
        const SizedBox(height: AppSpace.x24),
        const _Headline(
          '이제 툭 던져볼까요?',
          '절친 몇 명만 모으면 바로 쓸 수 있어요.',
          center: true,
        ),
        const SizedBox(height: AppSpace.x32),
        for (final s in _summaries) ...[
          SummaryCard(s),
          if (s != _summaries.last) const SizedBox(height: AppSpace.x10),
        ],
      ],
    );
  }
}
