import 'package:flutter/material.dart';

import 'tokens.dart';

/// 툭 앱 테마 — 코랄 포인트, 따뜻한 크림 배경, Pretendard.
/// 세밀한 타이포는 [AppText] 를 직접 쓰고, 여기서는 앱 전역 기본값만 잡는다.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryPress,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.textSub,
      outline: AppColors.border,
      error: AppColors.primaryPress, // 경고색 미사용 — 강조는 코랄 계열로
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
