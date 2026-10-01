import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/open_routes.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/friend.dart';
import '../services/api_client.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'delete_account_sheet.dart';
import 'friend_add_sheet.dart';
import 'landing_screen.dart';

/// 친구 화면 (10a/10b) — 받은 신청 수락 + 내 절친 목록 + 친구 추가.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with OpenRouteTracking<FriendsScreen> {
  @override
  String get openRouteKey => 'friends';

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

  /// 친구 끊기 — 양쪽 목록에서 조용히 사라진다. 되돌리려면 초대 코드부터라 한 번 더 묻는다.
  Future<void> _unfriend(Friend f) async {
    final fvm = context.read<FriendViewModel>();
    final done = await showConfirmSheet(
      context,
      title: '${f.nickname}님과 친구를 끊을까요?',
      lines: [
        '${f.nickname}님 목록에서도 조용히 빠져요. 따로 알리지 않아요.',
        '이미 함께한 모임은 그대로 남아요.',
        '다시 친구가 되려면 초대 코드를 주고받아야 해요.',
      ],
      confirmLabel: '친구 끊기',
      cancelLabel: '그대로 둘게요',
      onConfirm: () => fvm.unfriend(f),
    );
    if (done && mounted) showTukToast(context, '친구를 끊었어요');
  }

  Future<void> _cancelRequest(SentFriendRequest r) async {
    try {
      await context.read<FriendViewModel>().cancelRequest(r);
      if (mounted) showTukToast(context, '신청을 취소했어요');
    } on ApiException catch (e) {
      if (mounted) showTukToast(context, e.message);
    }
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDeleteAccountSheet(context);
    if (!deleted || !mounted) return;
    // 토스트는 앱 루트 ScaffoldMessenger 에 뜨므로 화면을 바꾸기 전에 띄워도 랜딩에서 보인다
    showTukToast(context, '탈퇴했어요. 그동안 고마웠어요');
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
                        _sectionHeader('내 친구', vm.friends.length),
                        const SizedBox(height: AppSpace.x12),
                        if (vm.friends.isEmpty)
                          const _EmptyFriends()
                        else
                          ...vm.friends.map((f) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.x8),
                                child: _FriendRow(friend: f, onMore: () => _unfriend(f)),
                              )),
                        if (vm.sentRequests.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.x32),
                          _sectionHeader('보낸 신청', vm.sentRequests.length),
                          const SizedBox(height: AppSpace.x12),
                          ...vm.sentRequests.map((r) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.x8),
                                child: _SentRequestRow(request: r, onCancel: () => _cancelRequest(r)),
                              )),
                          const SizedBox(height: AppSpace.x12),
                          Center(
                            child: Text('수락하면 알려줄게요',
                                style: AppText.caption12),
                          ),
                        ],
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
              if (v == 'delete') _deleteAccount();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              const PopupMenuItem(value: 'delete', child: Text('탈퇴하기')),
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

/// 보낸 신청 한 줄 — 읽기 전용. 친구 목록보다 덜 중요하니 흐리게, 아래에 둔다.
///
/// 문구에 주의: "수락 대기"처럼 *상대가 안 해주고 있다*로 읽히면 안 된다.
/// 툭은 거절이 안 보이는 앱이고, 실제로는 상대가 아직 앱을 안 열었을 뿐인 경우가 대부분이다.
class _SentRequestRow extends StatelessWidget {
  const _SentRequestRow({required this.request, required this.onCancel});
  final SentFriendRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: 0.6,
            child: InitialAvatar(
                nickname: request.nickname,
                imageUrl: request.profileImage,
                size: 36),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(request.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label15.copyWith(color: AppColors.textSub)),
          ),
          Text('기다리는 중', style: AppText.caption13),
          // 코드를 다시 넣으면 되돌릴 수 있어 확인 없이 바로 취소한다
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpace.x12),
              child: Text('취소',
                  style: AppText.caption13.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.border)),
            ),
          ),
        ],
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

/// 내 절친 행 — 아바타 + 이름, 오른쪽에 흐린 ⋯(친구 끊기). 자주 쓰는 동작이 아니라 눈에 띄지 않게.
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.onMore});
  final Friend friend;
  final VoidCallback onMore;

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
          GestureDetector(
            onTap: onMore,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(AppSpace.x4),
              child: Icon(Icons.more_horiz, size: 20, color: AppColors.border),
            ),
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
              Text('아직 친구가 없어요',
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
