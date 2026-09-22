import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/activity.dart';
import '../models/flash.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/flash_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/deep_link_handler.dart';
import '../widgets/logo.dart';
import '../widgets/presence.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'call_on_sheet.dart';
import 'flash_compose_screen.dart';
import 'friend_preview_sheet.dart';
import 'friends_screen.dart';
import 'home_coldstart_screen.dart';
import 'received_flashes_screen.dart';
import 'room_screen.dart';

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

  /// 홈 상단 배너 (11d): 내가 던진 툭(위) + 받은 툭(아래). 없으면 빈 리스트.
  List<Widget> _flashBanners(BuildContext context) {
    final flash = context.watch<FlashViewModel>();
    final sent = flash.sent;
    final pending = flash.pendingReceivedCount;
    if (sent.isEmpty && pending == 0) return const [];

    return [
      if (sent.isNotEmpty)
        _SentBanner(
          flash: sent.first,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RoomScreen(
                flashId: sent.first.flashId, expiresAt: sent.first.expiresAt),
          )),
        ),
      if (sent.isNotEmpty && pending > 0) const SizedBox(height: AppSpace.x8),
      if (pending > 0)
        _ReceivedBanner(
          count: pending,
          received: flash.received,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ReceivedFlashesScreen(),
          )),
        ),
      const SizedBox(height: AppSpace.x12),
    ];
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
                          child: Text('무시해도 상대에겐 아무것도 안 보여요',
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
          GestureDetector(
            onTap: _openFriends,
            behavior: HitTestBehavior.opaque,
            child: _ProfileAvatarButton(
              requestCount: context.select<FriendViewModel, int>(
                  (f) => f.requestCount),
            ),
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
          Text('아직 아무도 안 켰어요',
              style: AppText.title16.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpace.x4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              myOn
                  ? '켜져 있으니 괜찮아요. 친구가 한가해지면 바로 알려줄게요.'
                  : '친구가 한가해지면 여기 떠요.',
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
  const _Banner({required this.avatars, required this.title, required this.summary, required this.onTap});
  final List<({String nickname, String? profileImage})> avatars;
  final String title;
  final String summary;
  final VoidCallback onTap;

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
          border: Border.all(color: AppColors.primaryTintBorder),
        ),
        child: Row(
          children: [
            _BannerAvatars(avatars: avatars),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(summary,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.caption13.copyWith(color: AppColors.primaryPress)),
                ],
              ),
            ),
            const Text('›', style: TextStyle(
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
    if (show.isEmpty) {
      return const SizedBox(width: 32, height: 32);
    }
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

/// 내가 던진 툭 배너.
class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.flash, required this.onTap});
  final SentFlash flash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = flash.joinedCount;
    final expiry = flash.expiresAt != null ? flashExpiryText(flash.expiresAt!) : '';
    final who = n == 0 ? '아직 아무도' : '$n명 모였어요';
    return _Banner(
      avatars: flash.joined,
      title: '내가 던진 툭',
      summary: '${flash.activity.label} · $who · $expiry',
      onTap: onTap,
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
    return _Banner(
      avatars: pending
          .take(3)
          .map((f) => (nickname: f.senderNickname, profileImage: f.senderProfileImage))
          .toList(),
      title: '받은 툭 $count',
      summary: summary,
      onTap: onTap,
    );
  }
}

/// 프로필 아바타(나) + 받은 신청 배지. 탭하면 친구 화면으로.
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.requestCount});
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 내 정보가 아직 안 왔으면 이니셜 '나'로 버틴다(빈 원보다 낫다)
        InitialAvatar(
          nickname: context.watch<AuthViewModel>().me?.nickname ?? '나',
          imageUrl: context.watch<AuthViewModel>().me?.profileImage,
          size: 36,
        ),
        if (requestCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Text(
                requestCount > 9 ? '9+' : '$requestCount',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
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
              child: Text('나도 켜두면 친구가 먼저 부를 수 있어요',
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
