import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/keep_words.dart';

/// 원형 아바타 — 이미지 있으면 클립, 없으면 이니셜(틴트 배경 + 코랄 글자).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.nickname,
    this.imageUrl,
    this.size = 38,
  });

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
