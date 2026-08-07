import 'package:flutter/material.dart';

import 'tokens.dart';

/// 타이포 — Pretendard. 핸드오프 스케일 그대로.
/// 기본 색은 본문색(text). 필요하면 호출부에서 .copyWith(color:) 로 덮는다.
abstract final class AppText {
  static const _family = 'Pretendard';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.35,
    color: AppColors.text,
  );

  static const title20 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppColors.text,
  );

  static const title16 = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.text,
  );

  static const label15 = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.text,
  );

  static const label14 = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.text,
  );

  static const caption13 = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSub,
  );

  static const caption12 = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSub,
  );
}
