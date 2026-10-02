import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/activity.dart';
import '../models/flash.dart';
import '../viewmodels/flash_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/friends_entry.dart';
import '../widgets/deep_link_handler.dart';
import '../widgets/logo.dart';
import '../widgets/presence.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'call_on_sheet.dart';
import 'flash_compose_screen.dart';
import 'meet_time_sheet.dart' show meetTimeLabel;
import 'friend_preview_sheet.dart';
import 'friends_screen.dart';
import 'home_coldstart_screen.dart';
import 'received_flashes_screen.dart';
import 'room_screen.dart';
import '../core/keep_words.dart';

/// 로그인 이후 홈. 친구 수에 따라 콜드스타트(초대) vs 프레즌스 홈으로 분기.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PresenceViewModel>();

    if (!vm.initialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    // 공유 카드 링크(모임방·초대)는 로그인 후 홈이 자리 잡은 뒤 이 위로 연다.
    // 친구가 한 명도 없으면 콜드스타트(초대 유도).
    return DeepLinkHandler(
      child: vm.hasFriends ? const _PresenceHome() : const HomeColdstartScreen(),
    );
  }
}

class _PresenceHome extends StatefulWidget {
  const _PresenceHome();

  @override
  State<_PresenceHome> createState() => _PresenceHomeState();
}

class _PresenceHomeState extends State<_PresenceHome> {
  /// 진행 중인 모임을 홈에 몇 개까지 펼칠지. 넘치면 "+N개 더" 로 접는다 —
  /// 모임이 쌓여도 홈의 본래 목적("지금 한가한 친구")이 화면 밖으로 밀리지 않게.
  static const _meetupPreviewCount = 3;
  bool _expandedMeetups = false;

  Future<void> _openCallSheet({Activity? prefill}) async {
    final vm = context.read<PresenceViewModel>();
    final turnedOn = await showCallOnSheet(context, initialActivity: prefill);
    if (turnedOn != null && mounted) {
      showTukToast(context, '한가하다고 알렸어요 · ${turnedOn.label}');
    }
    // (vm 은 turnOn 내부에서 이미 갱신됨)
    if (vm.error != null && mounted) showTukToast(context, vm.error!);
  }

  Future<void> _onToggle() async {
    final vm = context.read<PresenceViewModel>();
    if (vm.myOn) {
      final err = await vm.turnOff();
      if (err != null && mounted) showTukToast(context, err);
    } else {
      await _openCallSheet();
    }
  }

  void _onFriendTap(AvailableFriend f) {
    showFriendPreviewSheet(context, f);
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  /// 홈 상단 (11d). 성격이 다른 둘을 나눠 보여준다.
  ///
  ///  - **받은 툭**: 아직 합류 안 한 것 — 내가 결정해야 하는 것들. 묶어서 한 줄.
  ///  - **진행 중인 모임**: 내가 띄운 것 + 내가 합류한 것 — 이미 성사된 모임들.
  ///
  /// 예전엔 내가 띄운 툭을 `sent.first` 로 **하나만** 그려서, 두 번째 툭을 띄우면
  /// 앞의 것이 사라진 것처럼 보였다(서버에는 다 살아 있었다).
  /// 친구 그룹은 겹치지 않으니 동시에 여러 모임이 있는 게 정상이다.
  List<Widget> _flashBanners(BuildContext context) {
    final flash = context.watch<FlashViewModel>();
    final pending = flash.pendingReceivedCount;
    final meetups = _ongoingMeetups(flash);
    if (meetups.isEmpty && pending == 0) return const [];

    final shown =
        _expandedMeetups ? meetups : meetups.take(_meetupPreviewCount).toList();

    return [
      if (pending > 0) ...[
        _ReceivedBanner(
          count: pending,
          received: flash.received,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ReceivedFlashesScreen(),
          )),
        ),
        const SizedBox(height: AppSpace.x8),
      ],
      if (meetups.isNotEmpty) ...[
        _MeetupsHeader(count: meetups.length),
        const SizedBox(height: AppSpace.x8),
        for (final m in shown) ...[
          _MeetupBanner(
            meetup: m,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  RoomScreen(flashId: m.flashId, expiresAt: m.expiresAt),
            )),
          ),
          const SizedBox(height: AppSpace.x8),
        ],
        if (meetups.length > shown.length)
          _MoreMeetups(
            more: meetups.length - shown.length,
            onTap: () => setState(() => _expandedMeetups = true),
          ),
      ],
      const SizedBox(height: AppSpace.x12),
    ];
  }

  /// 내가 띄운 것 + 내가 합류한 것을 한 목록으로. 임박한 순.
  ///
  /// 서버는 둘을 다른 엔드포인트로 준다(/sent, /received). 사용자에게는 둘 다
  /// "내가 껴 있는 모임"이라 여기서 합치되, 누가 띄웠는지는 줄마다 표시한다.
  List<_Meetup> _ongoingMeetups(FlashViewModel flash) {
    final list = <_Meetup>[
      for (final f in flash.sent) _Meetup.fromSent(f),
      for (final f in flash.received.where((f) => f.joined)) _Meetup.fromReceived(f),
    ];
    // 약속 시간이 있으면 그 시각, 없으면 합류 마감 기준으로 임박한 것부터
    list.sort((a, b) {
      final at = a.when, bt = b.when;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PresenceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.x20, 0, AppSpace.x20, 120),
                      children: [
                        ..._flashBanners(context),
                        NowCallCard(
                          on: vm.myOn,
                          activityLabel: vm.myActivity?.label,
                          expiresAt: vm.myExpiresAt,
                          highlighted: vm.highlightCall,
                          onToggle: _onToggle,
                          onEdit: () => _openCallSheet(prefill: vm.myActivity),
                        ),
                        const SizedBox(height: AppSpace.x32),
                        _sectionHeader(vm.friends.length),
                        const SizedBox(height: AppSpace.x12),
                        if (vm.friends.isEmpty)
                          _EmptyAvailable(myOn: vm.myOn)
                        else
                          ...vm.friends.map((f) => _FriendEnter(
                                key: ValueKey(f.userId),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpace.x8),
                                  child: FriendPresenceCard(
                                    nickname: f.nickname,
                                    profileImage: f.profileImage,
                                    activityLabel: f.activity.label,
                                    expiresAt: f.expiresAt,
                                    onTap: () => _onFriendTap(f),
                                  ),
                                ),
                              )),
                        if (!vm.myOn) ...[
                          const SizedBox(height: AppSpace.x16),
                          _TurnOnBanner(onTap: () => _openCallSheet()),
                        ],
                        const SizedBox(height: AppSpace.x24),
                        Center(
                          child: Text(keepWords('무시해도 상대에겐 아무것도 안 보여요'),
                              style: AppText.caption12),
                        ),
                      ],
                    ),
                  ),
                  _bottomCta(vm.myOn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpace.x20, right: AppSpace.x20, top: AppSpace.x8, bottom: AppSpace.x12),
      child: Row(
        children: [
          const TukLogo(size: 40),
          const Spacer(),
          FriendsEntryChip(
            onTap: _openFriends,
            requestCount:
                context.select<FriendViewModel, int>((f) => f.requestCount),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.x4),
      child: Text.rich(
        TextSpan(
          style: AppText.title20,
          children: [
            const TextSpan(text: '지금 한가한 친구 '),
            TextSpan(text: '$count',
                style: const TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _bottomCta(bool myOn) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.x20, AppSpace.x16, AppSpace.x20, 46),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.background, Color(0x00FBF7F1)],
            stops: [0.6, 1.0],
          ),
        ),
        child: myOn
            ? PillButton.primary(
                '툭 던지기',
                onPressed: () => Navigator.of(context).push(
                  flashComposeRoute(
                    prefillActivity: context.read<PresenceViewModel>().myActivity,
                  ),
                ),
              )
            : PillButton.primary(
                '한가하다고 알리기',
                onPressed: () => _openCallSheet(),
              ),
      ),
    );
  }
}

/// 한가한 친구 0명 (9c).
class _EmptyAvailable extends StatelessWidget {
  const _EmptyAvailable({required this.myOn});
  final bool myOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x24, vertical: AppSpace.x32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const _AvatarPlaceholders(),
          const SizedBox(height: AppSpace.x12),
          Text(keepWords('아직 아무도 안 켰어요'),
              style: AppText.title16.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpace.x4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(keepWords(
              myOn
                  ? '켜져 있으니 괜찮아요. 친구가 한가해지면 바로 알려줄게요.'
                  : '친구가 한가해지면 여기 떠요.'),
              textAlign: TextAlign.center,
              style: AppText.label14
                  .copyWith(color: AppColors.textSub, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// 겹친 점선 아바타 자리표시자 3개.
class _AvatarPlaceholders extends StatelessWidget {
  const _AvatarPlaceholders();

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.border, style: BorderStyle.solid, width: 1),
          ),
        );
    return SizedBox(
      height: 38,
      width: 38 * 3 - 20,
      child: Stack(
        children: [
          Positioned(left: 0, child: dot()),
          Positioned(left: 28, child: dot()),
          Positioned(left: 56, child: dot()),
        ],
      ),
    );
  }
}

/// 홈 상단 배너 공통 셸.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.avatars,
    required this.title,
    required this.summary,
    required this.onTap,
    this.badge,
    this.urgent = false,
  });
  final List<({String nickname, String? profileImage})> avatars;
  final String title;
  final String summary;
  final VoidCallback onTap;

  /// 있으면 제목 오른쪽에 작은 표시("내가 띄움"). 모임방의 '던진 사람' 배지와 같은 구분.
  final String? badge;

  /// 합류 마감이 코앞이면 테두리를 진하게. 경고가 아니라 "지금 눈이 가야 할 것" 표시다.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: urgent ? AppColors.primary : AppColors.primaryTintBorder,
              width: urgent ? 1.5 : 1),
        ),
        child: Row(
          children: [
            if (avatars.isNotEmpty) ...[
              _BannerAvatars(avatars: avatars),
              const SizedBox(width: AppSpace.x12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(keepWords(title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label15
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpace.x8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(keepWords(badge!),
                              style: AppText.caption12
                                  .copyWith(color: AppColors.primaryPress)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(keepWords(summary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.caption13.copyWith(color: AppColors.primaryPress)),
                ],
              ),
            ),
            Text(keepWords('›'), style: TextStyle(
                fontFamily: 'Pretendard', fontSize: 18, color: AppColors.primaryPress)),
          ],
        ),
      ),
    );
  }
}

/// 배너 안 아바타 스택 (32, 흰 배경, 틴트 테두리, 최대 3).
class _BannerAvatars extends StatelessWidget {
  const _BannerAvatars({required this.avatars});
  final List<({String nickname, String? profileImage})> avatars;

  @override
  Widget build(BuildContext context) {
    final show = avatars.take(3).toList();
    // 아직 아무도 안 모인 모임은 보여줄 얼굴이 없다. 빈 자리를 남기면 제목이 가운데로 밀린다.
    if (show.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 32,
      width: 32 + (show.length - 1) * 23.0,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 23.0,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.primaryTint, width: 2))),
                child: InitialAvatar(
                    nickname: show[i].nickname, imageUrl: show[i].profileImage, size: 32),
              ),
            ),
        ],
      ),
    );
  }
}

/// 홈 "진행 중인 모임" 한 줄. /sent 와 /received(합류) 를 같은 모양으로 다룬다.
class _Meetup {
  const _Meetup({
    required this.flashId,
    required this.title,
    required this.mine,
    required this.avatars,
    this.meetAt,
    this.expiresAt,
  });

  final int flashId;

  /// "밥 · 2명 모임" / "민수 · 밥" — 누구와 무엇을 하는지.
  final String title;

  /// 내가 띄운 모임인지. 남이 띄운 것과 심리적 무게가 달라서 줄마다 표시한다.
  final bool mine;

  final List<({String nickname, String? profileImage})> avatars;

  /// 약속 시간(정했으면). 합류 마감보다 이게 먼저다 — 실제로 궁금한 건 몇 시에 만나느냐다.
  final DateTime? meetAt;

  /// 합류 마감.
  final DateTime? expiresAt;

  /// 정렬 기준 시각. 합류가 끝났는데 시간도 안 정한 모임은 기준 시각이 없다 → 맨 뒤로
  /// (지난 마감 시각으로 정렬하면 오히려 맨 위로 올라온다).
  DateTime? get when => meetAt ?? (_unscheduledAfterClose ? null : expiresAt);

  /// 합류는 끝났는데 약속 시간이 없다. 서버가 마감 후 6시간까지 보여준다(MeetupLifecycle).
  bool get _unscheduledAfterClose =>
      meetAt == null && expiresAt != null && flashEnded(expiresAt!);

  /// 아직 모으는 중인데 마감이 코앞이면 눈에 띄어야 한다.
  /// 약속 시간이 잡힌 모임은 이미 성사된 것이라 마감이 급하지 않다.
  bool get urgent =>
      meetAt == null && expiresAt != null && flashEndingSoon(expiresAt!);

  /// 시간 한 줄. **약속 시간과 합류 마감은 다른 시각이라 둘 다 보여준다.**
  ///
  /// 약속이 먼저다 — 실제로 궁금한 건 몇 시에 만나느냐다. 마감은 뒤에 덧붙이되,
  /// 이미 지났으면 붙이지 않는다(더 들어올 사람이 없으니 알려줄 것도 없다).
  String get timeText {
    // 재촉하지 않고 상태만 알린다 — 홈에 남아 있는 것 자체가 "정해야지" 하는 신호다.
    if (_unscheduledAfterClose) return '시간 미정 · 합류는 끝났어요';
    final parts = <String>[];
    if (meetAt != null) parts.add(meetTimeLabel(meetAt!));
    if (expiresAt != null) {
      final stillOpen = expiresAt!.isAfter(DateTime.now());
      if (meetAt == null || stillOpen) parts.add(roomJoinDeadlineText(expiresAt!));
    }
    return parts.join(' · ');
  }

  factory _Meetup.fromSent(SentFlash f) => _Meetup(
        flashId: f.flashId,
        title: '${f.activity.label} · '
            '${f.joinedCount == 0 ? '아직 아무도' : '${f.joinedCount}명 모였어요'}',
        mine: true,
        avatars: f.joined,
        meetAt: f.meetAt,
        expiresAt: f.expiresAt,
      );

  factory _Meetup.fromReceived(ReceivedFlash f) => _Meetup(
        flashId: f.flashId,
        title: '${f.senderNickname} · ${f.activity.label}',
        mine: false,
        avatars: [(nickname: f.senderNickname, profileImage: f.senderProfileImage)],
        meetAt: f.meetAt,
        expiresAt: f.expiresAt,
      );
}

/// "진행 중인 모임 N" 머리줄.
class _MeetupsHeader extends StatelessWidget {
  const _MeetupsHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.x4, bottom: 2),
      child: Text.rich(TextSpan(
        style: AppText.label15.copyWith(fontWeight: FontWeight.w600),
        children: [
          const TextSpan(text: '진행 중인 모임 '),
          TextSpan(text: '$count', style: const TextStyle(color: AppColors.primary)),
        ],
      )),
    );
  }
}

/// 진행 중인 모임 한 줄. 누르면 그 모임방으로.
class _MeetupBanner extends StatelessWidget {
  const _MeetupBanner({required this.meetup, required this.onTap});
  final _Meetup meetup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      avatars: meetup.avatars,
      title: meetup.title,
      summary: meetup.timeText,
      badge: meetup.mine ? '내가 던짐' : null,
      urgent: meetup.urgent,
      onTap: onTap,
    );
  }
}

/// 접어둔 모임 펼치기.
class _MoreMeetups extends StatelessWidget {
  const _MoreMeetups({required this.more, required this.onTap});
  final int more;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
        child: Center(
          child: Text(keepWords('+$more개 더 보기'),
              style: AppText.caption13.copyWith(
                  color: AppColors.primaryPress, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// 받은 번개 배너.
class _ReceivedBanner extends StatelessWidget {
  const _ReceivedBanner({required this.count, required this.received, required this.onTap});
  final int count;
  final List<ReceivedFlash> received;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 미합류 중 가장 임박한 것 기준 요약.
    final pending = received.where((f) => !f.joined).toList();
    final first = pending.isNotEmpty ? pending.first : (received.isNotEmpty ? received.first : null);
    final String summary;
    if (first == null) {
      summary = '';
    } else if (count >= 2) {
      summary = '${first.senderNickname} 외 ${count - 1}명 · 곧 끝나는 것부터';
    } else {
      final t = first.expiresAt != null ? flashExpiryText(first.expiresAt!) : '';
      summary = '${first.senderNickname} · ${first.activity.label} · $t';
    }
    final soon = pending.any((f) =>
        f.expiresAt != null && flashEndingSoon(f.expiresAt!));
    return _Banner(
      avatars: pending
          .take(3)
          .map((f) => (nickname: f.senderNickname, profileImage: f.senderProfileImage))
          .toList(),
      urgent: soon,
      title: '받은 툭 $count',
      summary: summary,
      onTap: onTap,
    );
  }
}


/// 새 친구가 목록에 나타날 때 페이드+확장(240ms). userId 키라 기존 항목은
/// 상태를 유지해 재애니메이션되지 않고, 텍스트만 매 tick 갱신된다.
class _FriendEnter extends StatefulWidget {
  const _FriendEnter({super.key, required this.child});
  final Widget child;

  @override
  State<_FriendEnter> createState() => _FriendEnterState();
}

class _FriendEnterState extends State<_FriendEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();
  late final Animation<double> _curved =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curved,
      child: FadeTransition(opacity: _curved, child: widget.child),
    );
  }
}

/// 콜 꺼짐일 때 유도 배너 (9b).
class _TurnOnBanner extends StatelessWidget {
  const _TurnOnBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.x10),
            Expanded(
              child: Text(keepWords('나도 켜두면 친구가 먼저 부를 수 있어요'),
                  style: AppText.label14.copyWith(
                      color: AppColors.primaryPress,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
