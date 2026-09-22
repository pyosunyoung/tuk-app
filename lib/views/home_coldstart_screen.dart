import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/logo.dart';
import '../widgets/presence.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'call_on_sheet.dart';
import 'friend_add_sheet.dart';
import 'friends_screen.dart';

/// 홈 — 콜드스타트 (1b). 로그인 직후, 친구 0명 상태. 친구 초대를 유도한다.
///
/// 내 콜 상태는 홈과 똑같이 [PresenceViewModel](=서버)을 따른다.
/// 예전엔 화면 로컬 상태로 '기본 ON'을 그렸는데, 서버엔 꺼져 있어서
/// 신규 가입자에게 켜지지도 않은 콜이 켜진 것처럼 보였다(운영 E2E 에서 발견).
class HomeColdstartScreen extends StatefulWidget {
  const HomeColdstartScreen({super.key});

  @override
  State<HomeColdstartScreen> createState() => _HomeColdstartScreenState();
}

class _HomeColdstartScreenState extends State<HomeColdstartScreen> {
  /// 홈(_PresenceHome._onToggle)과 같은 동작: 켜져 있으면 끄고, 꺼져 있으면 켜기 시트.
  Future<void> _toggleCall() async {
    final vm = context.read<PresenceViewModel>();
    if (vm.myOn) {
      final err = await vm.turnOff();
      if (err != null && mounted) showTukToast(context, err);
      return;
    }
    final turnedOn = await showCallOnSheet(context);
    if (turnedOn != null && mounted) {
      showTukToast(context, '한가하다고 알렸어요 · ${turnedOn.label}');
    }
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
              child: _nowCallCard(),
            ),
            const Expanded(child: _EmptyState()),
            _bottomActions(),
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
          // 프로필 아바타 — 친구 화면 진입 (/users/me 붙기 전 임시 이니셜).
          GestureDetector(
            onTap: _openFriends,
            behavior: HitTestBehavior.opaque,
            // 내 정보가 아직 안 왔으면 이니셜 '나'로 버틴다(홈과 동일)
            child: InitialAvatar(
              nickname: context.watch<AuthViewModel>().me?.nickname ?? '나',
              imageUrl: context.watch<AuthViewModel>().me?.profileImage,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nowCallCard() {
    // 만료 문구는 vm 의 1분 tick 이 notify 하므로 따로 타이머가 필요 없다.
    final vm = context.watch<PresenceViewModel>();
    final callOn = vm.myOn;
    final expiresAt = vm.myExpiresAt;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        color: callOn ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
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
                      decoration: BoxDecoration(
                        color: callOn ? AppColors.success : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x8),
                    Flexible(
                      child: Text(
                        // 홈과 같은 규칙 — 라벨은 고정, 상태는 스위치와 아래 설명이 말한다.
                        '지금 한가해요',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title20.copyWith(
                          color: callOn ? AppColors.text : AppColors.textSub,
                          fontWeight:
                              callOn ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpace.x16, top: AppSpace.x4),
                  child: Text(
                    callOn
                        ? [
                            vm.myActivity?.label ?? '아무거나',
                            if (expiresAt != null) callExpiryText(expiresAt),
                          ].join(' · ')
                        : '켜두면 한가할 때 친구에게만 보여요',
                    style: AppText.label14,
                  ),
                ),
              ],
            ),
          ),
          _CallToggle(on: callOn, onTap: _toggleCall),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.x20, 0, AppSpace.x20, AppSpace.x20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillButton.primary(
            '친구 초대하기',
            onPressed: () => showFriendAddSheet(context),
          ),
          const SizedBox(height: AppSpace.x12),
          PillButton.secondary(
            '내 코드 알려주기',
            onPressed: () => showFriendAddSheet(context, startAtMyCode: true),
          ),
          const SizedBox(height: AppSpace.x12),
          Text('코드로만 친구가 돼요 · 낯선 사람은 들어올 수 없어요',
              textAlign: TextAlign.center, style: AppText.caption12),
        ],
      ),
    );
  }
}

/// 지금 콜 토글 52×32, 노브 26.
class _CallToggle extends StatelessWidget {
  const _CallToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x8, vertical: AppSpace.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TukLogo(size: 96, variant: TukLogoVariant.light),
            const SizedBox(height: AppSpace.x16),
            Text('아직 절친이 없어요',
                textAlign: TextAlign.center,
                style: AppText.title20.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpace.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                '먼저 켜두면 친구가 한가해질 때 알려줄게요',
                textAlign: TextAlign.center,
                style: AppText.body
                    .copyWith(color: AppColors.textSub, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
