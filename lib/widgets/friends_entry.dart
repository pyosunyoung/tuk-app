import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import 'avatar.dart';
import '../core/keep_words.dart';

/// 친구 화면으로 가는 입구 (홈·콜드스타트 공통).
///
/// 예전에는 우상단에 아바타만 덩그러니 있었다. 아바타는 관습적으로 "내 프로필"로 읽혀서
/// 여기에 친구 목록이 있다는 단서가 없었다 — 만든 사람만 아는 길이었다.
/// 그래서 아바타에 "친구" 라벨을 붙여 알약으로 감쌌다.
///
/// 받은 신청이 있으면 숫자 배지가 뜬다.
class FriendsEntryChip extends StatelessWidget {
  const FriendsEntryChip({super.key, required this.requestCount, required this.onTap});

  final int requestCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthViewModel>().me;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, AppSpace.x12, 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 내 정보가 아직 안 왔으면 이니셜 '나'로 버틴다(빈 원보다 낫다)
                InitialAvatar(
                  nickname: me?.nickname ?? '나',
                  imageUrl: me?.profileImage,
                  size: 28,
                ),
                const SizedBox(width: AppSpace.x8),
                Text(keepWords(
                  '친구'),
                  style: AppText.label14.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
                child: Text(keepWords(
                  requestCount > 9 ? '9+' : '$requestCount'),
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
      ),
    );
  }
}
