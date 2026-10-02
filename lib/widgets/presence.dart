import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../core/keep_words.dart';

// ─────────────────────────────────────────── 만료/남은시간 문구

/// 내 콜 카드용 만료 문구. 부담 없는 표현.
String callExpiryText(DateTime expiresAt) {
  final diff = expiresAt.difference(DateTime.now());
  if (diff.inSeconds <= 0) return '곧 자동으로 꺼져요';
  if (expiresAt.hour == 0 && expiresAt.minute == 0) {
    return '자정에 자동으로 꺼져요';
  }
  final m = diff.inMinutes;
  if (m >= 60) {
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h시간 뒤 자동으로 꺼져요' : '$h시간 $r분 뒤 자동으로 꺼져요';
  }
  return '$m분 뒤 자동으로 꺼져요';
}

/// 친구 카드용 남은시간(더 짧게). 10분 미만은 초읽기 대신 "곧 꺼져요".
String friendRemainingText(DateTime expiresAt) {
  final diff = expiresAt.difference(DateTime.now());
  final m = diff.inMinutes;
  if (m < 10) return '곧 꺼져요';
  if (m >= 60) {
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h시간 남음' : '$h시간 $r분 남음';
  }
  return '$m분 남음';
}

// ─────────────────────────────────────────── 활동 태그 칩

/// 친구 카드 안의 작은 활동 태그.
class ActivityChip extends StatelessWidget {
  const ActivityChip(this.label, {super.key});
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

// ─────────────────────────────────────────── 콜 토글 52×32

class CallToggle extends StatelessWidget {
  const CallToggle({super.key, required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x292B2926),
                  blurRadius: 3,
                  offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 지금 콜 카드

/// 내 콜 카드. 켜짐/꺼짐 + 방금 켠 강조.
/// 본문(토글 제외) 탭 → onEdit(수정 시트), 토글 탭 → onToggle.
class NowCallCard extends StatelessWidget {
  const NowCallCard({
    super.key,
    required this.on,
    this.activityLabel,
    this.expiresAt,
    required this.onToggle,
    this.onEdit,
    this.highlighted = false,
  });

  final bool on;
  final String? activityLabel;
  final DateTime? expiresAt;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: on ? onEdit : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpace.x20),
        decoration: BoxDecoration(
          color: on ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: highlighted ? AppColors.primaryTintBorder : AppColors.border),
          boxShadow: highlighted
              ? const [
                  BoxShadow(
                      color: Color(0x24FF7A5C),
                      blurRadius: 16,
                      offset: Offset(0, 4)),
                ]
              : null,
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
                          color: on ? AppColors.success : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      Flexible(
                        child: Text(keepWords(
                          // 라벨은 켜짐/꺼짐에 따라 바뀌지 않는다 — 상태는 오른쪽 스위치가 말한다.
                          // 무엇을 켜는 건지는 라벨이, 지금 어떤지는 스위치와 아래 설명이 맡는다.
                          '지금 한가해요'),
                          style: AppText.title20.copyWith(
                            color: on ? AppColors.text : AppColors.textSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x4),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpace.x16),
                    child: Text(keepWords(
                      on
                          ? [
                              if (activityLabel != null && activityLabel!.isNotEmpty) activityLabel!,
                              if (expiresAt != null) callExpiryText(expiresAt!),
                            ].join(' · ')
                          : '켜두면 한가할 때 친구에게만 보여요'),
                      style: AppText.label14.copyWith(color: AppColors.textSub),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x12),
            CallToggle(on: on, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 친구 카드

/// 지금 한가한 친구 한 명. 전체가 탭 타깃.
class FriendPresenceCard extends StatelessWidget {
  const FriendPresenceCard({
    super.key,
    required this.nickname,
    this.profileImage,
    required this.activityLabel,
    required this.expiresAt,
    required this.onTap,
  });

  final String nickname;
  final String? profileImage;
  final String activityLabel;
  final DateTime expiresAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _Avatar(nickname: nickname, imageUrl: profileImage, size: 38),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(keepWords(nickname),
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label15
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      ActivityChip(activityLabel),
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
                      const SizedBox(width: 5),
                      Text(keepWords('지금 한가함'),
                          style: AppText.caption12.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Text(keepWords(friendRemainingText(expiresAt)), style: AppText.caption12),
          ],
        ),
      ),
    );
  }
}

/// 원형 아바타 — 이미지 있으면 클립, 없으면 이니셜.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.nickname, this.imageUrl, required this.size});
  final String nickname;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isNotEmpty ? nickname.characters.first : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
          color: AppColors.primaryTint, shape: BoxShape.circle),
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover)
          : Text(keepWords(initial),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPress,
              )),
    );
  }
}
