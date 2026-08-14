import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/friend.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'friend_add_sheet.dart';
import 'landing_screen.dart';

/// 친구 화면 (10a/10b) — 받은 신청 수락 + 내 절친 목록 + 친구 추가.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<void> _accept(FriendRequest r) async {
    final fvm = context.read<FriendViewModel>();
    final name = await fvm.accept(r.friendshipId);
    if (!mounted) return;
    if (name != null) {
      showTukToast(context, '$name과 친구가 됐어요');
      context.read<PresenceViewModel>().load(); // 홈 친구수 갱신
    } else {
      showTukToast(context, fvm.error ?? '잠시 후 다시 시도해 주세요');
    }
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendViewModel>();
    final hasRequests = vm.requests.isNotEmpty;

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
                        if (hasRequests) ...[
                          const SizedBox(height: AppSpace.x12),
                          _sectionHeader('받은 신청', vm.requests.length),
                          const SizedBox(height: AppSpace.x12),
                          ...vm.requests.map((r) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.x8),
                                child: _RequestCard(
                                    request: r, onAccept: () => _accept(r)),
                              )),
                          const SizedBox(height: AppSpace.x12),
                          Center(
                            child: Text('그냥 둬도 괜찮아요. 상대에겐 아무것도 안 보여요',
                                style: AppText.caption12),
                          ),
                        ],
                        SizedBox(
                            height: hasRequests ? AppSpace.x32 : AppSpace.x12),
                        _sectionHeader('내 절친', vm.friends.length),
                        const SizedBox(height: AppSpace.x12),
                        if (vm.friends.isEmpty)
                          const _EmptyFriends()
                        else
                          ...vm.friends.map((f) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.x8),
                                child: _FriendRow(friend: f),
                              )),
                      ],
                    ),
                  ),
                  _bottomCta(),
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
          left: AppSpace.x20, right: AppSpace.x8, top: AppSpace.x8, bottom: AppSpace.x12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.arrow_back, size: 22, color: AppColors.text),
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          Text('친구', style: AppText.title20),
          const Spacer(),
          // 로그아웃은 본문이 아니라 ⋯ 메뉴에(임시, 설정 화면 생기면 이동).
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSub),
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.x4),
      child: Text.rich(
        TextSpan(
          style: AppText.title16,
          children: [
            TextSpan(text: '$title '),
            TextSpan(text: '$count',
                style: const TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _bottomCta() {
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
        child: PillButton.primary(
          '친구 추가',
          onPressed: () => showFriendAddSheet(context),
        ),
      ),
    );
  }
}

/// 받은 신청 카드 — 테두리 tint + "수락"만 (거절 버튼 없음).
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onAccept});
  final FriendRequest request;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.x16, AppSpace.x12, AppSpace.x12, AppSpace.x12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primaryTintBorder),
      ),
      child: Row(
        children: [
          InitialAvatar(nickname: request.nickname, imageUrl: request.profileImage),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(request.nickname,
                overflow: TextOverflow.ellipsis,
                style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpace.x8),
          _AcceptButton(onTap: onAccept),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text('수락',
            style: AppText.label14
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// 내 절친 행 — 아바타 + 이름, 오른쪽에 아무것도 없음.
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialAvatar(nickname: friend.nickname, imageUrl: friend.profileImage),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(friend.nickname,
                overflow: TextOverflow.ellipsis,
                style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// 친구 0명 빈 상태 (10b).
class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x24, vertical: AppSpace.x32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const _DashedPlaceholders(),
              const SizedBox(height: AppSpace.x12),
              Text('아직 절친이 없어요',
                  style: AppText.title16.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpace.x4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  '코드를 주고받으면 바로 친구가 돼요. 검색으로는 아무도 찾을 수 없어요.',
                  textAlign: TextAlign.center,
                  style: AppText.label14
                      .copyWith(color: AppColors.textSub, height: 1.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x24),
        Text('낯선 사람은 들어올 수 없어요', style: AppText.caption12),
      ],
    );
  }
}

class _DashedPlaceholders extends StatelessWidget {
  const _DashedPlaceholders();

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
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
