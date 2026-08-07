import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';

/// 하단 토스트 — 다크 pill, 흰 글씨, 1.8초. (핸드오프 실패 토스트 규격)
void showTukToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      elevation: 0,
      duration: const Duration(milliseconds: 1800),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.label14.copyWith(color: Colors.white),
      ),
    ),
  );
}
