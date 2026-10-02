import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/presence.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';
import 'flash_compose_screen.dart';
import '../core/keep_words.dart';

/// 친구 카드 탭 → 미리보기 시트 (9e).
/// 여기까지가 프레즌스 범위. "툭 던지기"는 발송 상세(별도 기능)로 넘어가며,
/// 지금은 네비게이션/파라미터 전달 자리에 안내 토스트만 둔다.
///
/// 연 시점의 [friend] 정보를 기억하고, 온/오프라인 여부만 실시간으로 판정한다
/// (상대가 시트를 연 사이 콜을 꺼도 이름/활동은 유지, CTA 만 비활성).
Future<void> showFriendPreviewSheet(BuildContext context, AvailableFriend friend) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _FriendPreviewSheet(friend: friend),
  );
}

class _FriendPreviewSheet extends StatelessWidget {
  const _FriendPreviewSheet({required this.friend});
  final AvailableFriend friend;

  @override
  Widget build(BuildContext context) {
    final live = context
        .watch<PresenceViewModel>()
        .friends
        .where((f) => f.userId == friend.userId)
        .firstOrNull;
    final online = live != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          const SizedBox(height: AppSpace.x20),
          _ProfileRow(friend: friend, liveExpiresAt: live?.expiresAt),
          const SizedBox(height: AppSpace.x24),
          if (online)
            PillButton.primary(
              '${friend.nickname}에게 툭 던지기',
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(flashComposeRoute(
                  prefillActivity: friend.activity,
                  prefillTargetIds: [friend.userId],
                ));
              },
            )
          else ...[
            _DisabledButton('${friend.nickname}에게 툭 던지기'),
            const SizedBox(height: AppSpace.x8),
            Text(keepWords('지금은 한가하지 않대요. 그래도 던져두면 나중에 봐요.'),
                textAlign: TextAlign.center, style: AppText.caption12),
          ],
          const SizedBox(height: AppSpace.x12),
          PillButton.secondary(
            '친구 모두에게 던지기',
            onPressed: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(flashComposeRoute(prefillActivity: friend.activity));
            },
          ),
          const SizedBox(height: AppSpace.x12),
          Center(
            child: Text(keepWords('무시해도 상대에겐 아무것도 안 보여요'),
                style: AppText.caption12),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.friend, this.liveExpiresAt});
  final AvailableFriend friend;
  final DateTime? liveExpiresAt; // null 이면 오프라인

  @override
  Widget build(BuildContext context) {
    final initial =
        friend.nickname.isNotEmpty ? friend.nickname.characters.first : '?';
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: AppColors.primaryTint, shape: BoxShape.circle),
          child: Text(keepWords(initial),
              style: AppText.title20.copyWith(color: AppColors.primaryPress)),
        ),
        const SizedBox(width: AppSpace.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(keepWords(friend.nickname),
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title20),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  ActivityChip(friend.activity.label),
                ],
              ),
              const SizedBox(height: AppSpace.x4),
              if (liveExpiresAt == null)
                Text(keepWords('지금은 한가하지 않아요'), style: AppText.caption12)
              else
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(keepWords('지금 한가함'),
                        style: AppText.caption12.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500)),
                    Text(keepWords(' · ${friendRemainingText(liveExpiresAt!)}'),
                        style: AppText.caption12),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 비활성(탭 불가) 주 버튼.
class _DisabledButton extends StatelessWidget {
  const _DisabledButton(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSize.ctaHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(keepWords(label),
          style: AppText.title16.copyWith(color: AppColors.textSub)),
    );
  }
}
