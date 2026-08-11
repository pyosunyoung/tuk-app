import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/activity.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/logo.dart';
import '../widgets/presence.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'call_on_sheet.dart';
import 'home_coldstart_screen.dart';
import 'landing_screen.dart';

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
    // 친구가 한 명도 없으면 콜드스타트(초대 유도).
    if (!vm.hasFriends) return const HomeColdstartScreen();
    return const _PresenceHome();
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
      showTukToast(context, '지금 콜을 켰어요 · ${turnedOn.label}');
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
    // 미리보기 시트(9e)는 다음 커밋에서. 지금은 안내만.
    showTukToast(context, '${f.nickname} 미리보기 — 다음 단계에서 연결');
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
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
                          ...vm.friends.map((f) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.x8),
                                child: FriendPresenceCard(
                                  nickname: f.nickname,
                                  profileImage: f.profileImage,
                                  activityLabel: f.activity.label,
                                  expiresAt: f.expiresAt,
                                  onTap: () => _onFriendTap(f),
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
            onTap: _logout,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Text('나',
                  style: AppText.label14.copyWith(
                      color: AppColors.primaryPress,
                      fontWeight: FontWeight.w600)),
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
                '툭 띄우기',
                onPressed: () =>
                    showTukToast(context, '번개(툭) 발송은 다음 기능에서 연결됩니다'),
              )
            : PillButton.primary(
                '지금 콜 켜기',
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
