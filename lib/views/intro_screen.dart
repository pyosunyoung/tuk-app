import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/keep_words.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/logo.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'home_screen.dart';

/// 인트로 6컷 (6b) — 왜 필요한지(상황) → 어떻게 해결하는지(기능) → 모인 다음.
/// 그림 속 문구는 실제 화면·알림과 같게 둔다(처음 받는 알림을 보고 "아, 그거구나" 하도록).
/// 좌우 스와이프 + "다음" 버튼. 마지막 컷에서 카카오(dev) 로그인.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _cutCount = 6;
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
    final ok = await auth.loginWithKakao();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (auth.error != null) {
      // error == null 이면 사용자가 취소한 것 — 아무 말도 하지 않는다
      showTukToast(context, auth.error!);
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
                          child: Text(keepWords('건너뛰기'),
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
                  _Cut1(), // 갑자기 시간이 비는 날
                  _Cut2(), // 누가 한가한지 먼저 보여요
                  _Cut3(), // 툭 던지면 알림이 딱
                  _CutRoom(), // 모이면 언제·어디서만
                  _Cut4(), // 그리고 알아서 꺼져요
                  _Cut5(), // 이제 툭 던져볼까요?
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
                    Text(keepWords('가입만으로는 아무에게도 알림이 가지 않아요'),
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
        // 단어 중간에서 줄이 넘어가지 않게(keepWords)
        Text(keepWords(title), style: AppText.display, textAlign: align),
        const SizedBox(height: AppSpace.x12),
        Text(keepWords(body),
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
              Text(keepWords('단톡방 · 우리들'),
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
                    child: Text(keepWords('오늘 저녁에 누구 시간 돼?'),
                        style: AppText.label15
                            .copyWith(fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.x4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(keepWords('오후 6:12'), style: AppText.caption12),
              ),
              const SizedBox(height: AppSpace.x12),
              _skeleton(0.56, const Color(0xFFF4F0EA)),
              const SizedBox(height: AppSpace.x8),
              _skeleton(0.38, const Color(0xFFF7F4EF)),
              const SizedBox(height: AppSpace.x12),
              Center(child: Text(keepWords('…답장 없음'), style: AppText.caption13)),
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
          '개인톡으로 하나하나 물어볼 필요 없어요. 지금 한가하다고 알린 친구만 목록에 떠요.',
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
            child: Text(keepWords(initial),
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
                  Text(keepWords(name),
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
                  Text(keepWords('지금 한가함'),
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
      child: Text(keepWords(label),
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
                        Text(keepWords('툭'),
                            style: AppText.caption13.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(keepWords('지금'), style: AppText.caption12),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 실제 푸시와 같은 문구(서버 FlashPushListener) — 처음 받는 알림과 같아야 알아본다
                    Text(keepWords('민수님이 툭 던졌어요'),
                        style: AppText.label14
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(keepWords('술 · 지금 볼래?'),
                        style: AppText.label14
                            .copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        // 받은 툭 카드 — 실제 화면처럼 "합류하기" 하나뿐. 거절 버튼은 없다(안 누르면 그만).
        _Card(
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(keepWords('민수 · 술'),
                      style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(keepWords('52분 뒤 끝나요'), style: AppText.caption12),
                ],
              ),
              const SizedBox(height: AppSpace.x4),
              Text(keepWords('지금 볼래?'), style: AppText.caption13),
              const SizedBox(height: AppSpace.x12),
              const _MiniButton('합류하기', filled: true),
              const SizedBox(height: AppSpace.x12),
              Center(
                child: Text(keepWords('안 누르고 지나쳐도 민수에겐 아무것도 안 보여요'),
                    style: AppText.caption12),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '툭 던지면 알림이 딱',
          '한 탭이면 친한 친구들에게 바로 닿아요. 지나쳐도 보낸 사람에겐 아무것도 안 보여서 서로 부담이 없어요.',
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
      child: Text(keepWords(
        label),
        style: AppText.label15.copyWith(
          color: filled ? Colors.white : AppColors.textSub,
          fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 4 (모임방)

/// 합류한 다음. 예전 인트로는 "툭 던지기"에서 끝나서 그다음에 뭘 하는지 몰랐다.
/// 9월에 만든 것들(약속 시간·장소 검색·지도·카톡 넘기기·변경 알림)을 한 장에 보여준다.
class _CutRoom extends StatelessWidget {
  const _CutRoom();

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      children: [
        // 변경 알림 (실제 푸시 문구와 같은 모양)
        _Card(
          border: false,
          shadow: const [
            BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, 8)),
          ],
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 12),
          child: Row(
            children: [
              const TukLogo(size: 28),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text(keepWords('술 · 장소가 바뀌었어요'),
                    style: AppText.label14.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(keepWords('지금'), style: AppText.caption12),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        // 모임방 카드
        _Card(
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoomRow(label: '언제', value: '오늘 오후 8시', note: '지호님이 정했어요'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.x12),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _RoomRow(label: '어디서', value: '망원역', note: '민수님이 바꿨어요'),
              const SizedBox(height: AppSpace.x8),
              Row(
                children: [
                  const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpace.x4),
                  Text(keepWords('지도에서 보기'),
                      style: AppText.caption13.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpace.x16),
              Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE500),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(keepWords('카톡으로 이야기하기'),
                    style: AppText.label14.copyWith(
                        color: const Color(0xFF191600), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: AppSpace.x12),
              Text(keepWords('민수 · 지호 · 나  3명 모였어요'), style: AppText.caption12),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        const _Headline(
          '모이면 언제·어디서만\n정하면 돼요',
          '장소는 검색해서 고르고 지도로 바로 열어요. 바뀌면 다 같이 알림을 받고, 이야기는 카톡에서 이어가요.',
        ),
      ],
    );
  }
}

/// 모임방 카드의 한 줄 — 라벨 / 값 / 누가 정했는지.
class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.label, required this.value, required this.note});
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 48, child: Text(keepWords(label), style: AppText.caption13)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(keepWords(value), style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(keepWords(note), style: AppText.caption12),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── 컷 5 (알아서 꺼져요)

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
                        Text(keepWords('지금 한가해요'),
                            style: AppText.title16
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpace.x16, top: AppSpace.x4),
                      child: Text(keepWords('카페 · 1시간 32분 뒤 자동으로 꺼져요'),
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
              Text(keepWords('↓'),
                  style: AppText.title20.copyWith(
                      color: AppColors.textSub, fontWeight: FontWeight.w500)),
              const SizedBox(width: AppSpace.x8),
              Text(keepWords('시간이 지나면'),
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
              Text(keepWords('지금 한가해요'),
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
          // 9월 말부터 합류 마감 ≠ 모임 종료다. "던진 툭도 사라져요"는 사실과 달라 고쳤다.
          '한가하다는 표시도, 툭에 합류 받는 것도 시간이 지나면 끝나요. 끄는 걸 잊어도 부담이 남지 않고, 모인 약속은 그대로 남아요.',
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

  // 랜딩과 같은 세 줄(landing_screen.dart). 둘이 다르게 말하면 안 된다.
  static const _summaries = [
    '한가한 친구가 먼저 보여요',
    '거절은 아무에게도 안 보여요',
    '한가함은 시간 지나면 알아서 꺼져요',
  ];

  @override
  Widget build(BuildContext context) {
    return _CutBody(
      center: true,
      children: [
        const TukLogo(size: 72),
        const SizedBox(height: AppSpace.x24),
        // 닫힌 그룹 이야기를 여기서 — 첫 행동(친구 초대)으로 이어지게
        const _Headline(
          '이제 툭 던져볼까요?',
          '초대 코드를 주고받은 친한 친구끼리만 보여요.\n몇 명만 모으면 바로 쓸 수 있어요.',
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
