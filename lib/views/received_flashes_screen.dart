import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/open_routes.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/flash.dart';
import '../services/api_client.dart';
import '../viewmodels/flash_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/toast.dart';
import 'room_screen.dart';

/// 받은 번개 목록 (11b). 무시는 아무것도 하지 않는 것 — 거절 버튼 없음.
class ReceivedFlashesScreen extends StatefulWidget {
  const ReceivedFlashesScreen({super.key});

  @override
  State<ReceivedFlashesScreen> createState() => _ReceivedFlashesScreenState();
}

class _ReceivedFlashesScreenState extends State<ReceivedFlashesScreen>
    with OpenRouteTracking<ReceivedFlashesScreen> {
  @override
  String get openRouteKey => 'received';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashViewModel>().reloadReceived();
    });
  }

  Future<void> _open(ReceivedFlash f) async {
    final vm = context.read<FlashViewModel>();
    if (f.joined) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RoomScreen(flashId: f.flashId, expiresAt: f.expiresAt),
      ));
      return;
    }
    try {
      await vm.join(f.flashId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RoomScreen(
            flashId: f.flashId, expiresAt: f.expiresAt, initialToast: '합류했어요'),
      ));
    } on ApiException catch (e) {
      if (mounted) {
        showTukToast(context, vm.isEnded(e) ? '이 툭은 끝났어요' : e.message);
        vm.reloadReceived();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FlashViewModel>();
    final list = vm.received;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpace.x20, right: AppSpace.x20, top: AppSpace.x8, bottom: AppSpace.x12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(width: 36, height: 36,
                        child: Icon(Icons.arrow_back, size: 22, color: AppColors.text)),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Text.rich(TextSpan(style: AppText.title20, children: [
                    const TextSpan(text: '받은 툭 '),
                    TextSpan(text: '${list.length}',
                        style: const TextStyle(color: AppColors.primary)),
                  ])),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: vm.reloadReceived,
                child: list.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), _EmptyReceived()])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, 46),
                        children: [
                          ...list.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpace.x12),
                                child: _FlashCard(
                                    flash: f, onJoin: () => _open(f)),
                              )),
                          const SizedBox(height: AppSpace.x8),
                          Center(child: Text(
                              '그냥 둬도 괜찮아요 · 보낸 사람에겐 아무것도 안 보여요',
                              style: AppText.caption12)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.flash, required this.onJoin});
  final ReceivedFlash flash;

  /// 합류(또는 이미 합류했으면 모임방 열기). **버튼에서만** 불린다.
  final VoidCallback onJoin;

  bool get _reserved =>
      flash.scheduledAt != null && flash.scheduledAt!.isAfter(DateTime.now());

  bool get _endingSoon =>
      !_reserved && flash.expiresAt != null && flashEndingSoon(flash.expiresAt!);

  @override
  Widget build(BuildContext context) {
    final joined = flash.joined;
    // 카드 전체를 탭 타깃으로 두면 메시지를 읽으려다 합류된다.
    // 합류는 상대에게 보이는(되돌릴 수 없는) 행동이라 버튼에서만 받는다.
    // 이미 합류한 카드는 눌러도 모임방이 열릴 뿐이라 전체 탭을 허용한다.
    return GestureDetector(
      onTap: joined ? onJoin : null,
      behavior: joined ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.x16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          // 아직 합류 안 했고 마감이 코앞이면 테두리를 진하게(빨강 아님 — 재촉하지 않는다)
          border: Border.all(
              color: joined
                  ? AppColors.border
                  : (_endingSoon ? AppColors.primary : AppColors.primaryTintBorder),
              width: !joined && _endingSoon ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InitialAvatar(
                    nickname: flash.senderNickname,
                    imageUrl: flash.senderProfileImage,
                    size: 44),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(flash.senderNickname,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title16),
                          ),
                          const SizedBox(width: AppSpace.x8),
                          _Chip(flash.activity.label),
                          if (joined) ...[
                            const SizedBox(width: AppSpace.x8),
                            Container(width: 6, height: 6, decoration: const BoxDecoration(
                                color: AppColors.success, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('합류했어요', style: AppText.caption12.copyWith(
                                color: AppColors.success, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpace.x4),
                      _timeLine(),
                    ],
                  ),
                ),
              ],
            ),
            if (flash.message != null && flash.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x12),
              Text(flash.message!,
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: AppText.label15.copyWith(fontWeight: FontWeight.w400, height: 1.5)),
            ],
            const SizedBox(height: AppSpace.x16),
            _cta(joined),
          ],
        ),
      ),
    );
  }

  Widget _timeLine() {
    if (_reserved) {
      return Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.xsmall),
          ),
          child: Text(reservedTimeText(flash.scheduledAt!),
              style: AppText.caption12.copyWith(
                  color: AppColors.primaryPress, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: AppSpace.x8),
        Text('예약', style: AppText.caption12),
      ]);
    }
    return Text(
        flash.expiresAt != null ? flashExpiryText(flash.expiresAt!) : '',
        style: AppText.caption12);
  }

  Widget _cta(bool joined) {
    return GestureDetector(
      onTap: onJoin,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: joined ? AppColors.surface : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: joined ? Border.all(color: AppColors.border) : null,
          boxShadow: joined ? null : AppShadow.coralCta,
        ),
        child: Text(joined ? '모임방 열기' : '합류하기',
            style: AppText.label15.copyWith(
              color: joined ? AppColors.textSub : Colors.white,
              fontWeight: joined ? FontWeight.w500 : FontWeight.w600,
            )),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
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
      child: Text(label, style: AppText.caption12.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}

class _EmptyReceived extends StatelessWidget {
  const _EmptyReceived();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _placeholders(),
        const SizedBox(height: AppSpace.x12),
        Text('받은 툭이 없어요',
            style: AppText.title16.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpace.x4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text('친구가 툭 던지면 여기 떠요. 알림으로도 알려줄게요.',
              textAlign: TextAlign.center,
              style: AppText.label14.copyWith(color: AppColors.textSub, height: 1.55)),
        ),
      ]),
    );
  }

  Widget _placeholders() {
    Widget dot() => Container(width: 38, height: 38, decoration: BoxDecoration(
        color: AppColors.surface, shape: BoxShape.circle,
        border: Border.all(color: AppColors.border)));
    return SizedBox(height: 38, width: 38 * 3 - 20, child: Stack(children: [
      Positioned(left: 0, child: dot()),
      Positioned(left: 28, child: dot()),
      Positioned(left: 56, child: dot()),
    ]));
  }
}
