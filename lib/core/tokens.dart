import 'package:flutter/material.dart';

/// 디자인 토큰 — 핸드오프(design_handoff_tuk_auth)의 최종값 그대로.
/// HTML/CSS를 옮기지 않고, 색·간격·타이포·반경 값만 정확히 가져온다.

/// 색. 경고색(빨강) 없음. 포인트는 코랄 하나.
abstract final class AppColors {
  static const primary = Color(0xFFFF7A5C); // CTA, 브랜드 포인트, 활성 인디케이터
  static const primaryPress = Color(0xFFE85D3D); // 눌림, 아바타 이니셜 텍스트
  static const primaryTint = Color(0xFFFFEAE2); // 아바타 배경, 선택 칩, 말풍선
  static const primaryTintBorder = Color(0xFFFFD4C6); // 선택된 칩 테두리
  static const background = Color(0xFFFBF7F1); // 화면 배경(따뜻한 크림)
  static const surface = Color(0xFFFFFFFF); // 카드
  static const text = Color(0xFF2B2926); // 본문
  static const textSub = Color(0xFF8A857E); // 보조/비활성
  static const border = Color(0xFFECE7DF); // 카드 테두리, 비활성 토글/인디케이터
  static const success = Color(0xFF3DBE8B); // 합류/"지금 가능"
  static const accent = Color(0xFFFFC24B); // 로고 점 하나에만
  static const kakao = Color(0xFFFEE500); // 카카오 버튼 배경(텍스트는 text)
}

/// 간격 — 4의 배수만. 화면 좌우 여백은 20(버튼) 또는 24(콘텐츠).
abstract final class AppSpace {
  static const x4 = 4.0;
  static const x8 = 8.0;
  static const x10 = 10.0; // 카드 사이 등 일부 지점에서 사용
  static const x12 = 12.0;
  static const x16 = 16.0;
  static const x20 = 20.0;
  static const x24 = 24.0;
  static const x32 = 32.0;

  static const screenButtons = 20.0; // 버튼 영역 좌우 여백
  static const screenContent = 24.0; // 콘텐츠 영역 좌우 여백
}

/// 모서리 반경. 버튼·칩은 pill(999).
abstract final class AppRadius {
  static const card = 16.0;
  static const small = 12.0;
  static const xsmall = 8.0;
  static const pill = 999.0;
}

/// 그림자 — 거의 플랫.
abstract final class AppShadow {
  /// 인트로에서 카드가 떠 보여야 할 때
  static const List<BoxShadow> cardFloat = [
    BoxShadow(color: Color(0x0D2B2926), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// 코랄 CTA
  static const List<BoxShadow> coralCta = [
    BoxShadow(color: Color(0x47FF7A5C), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// 로고 타일
  static const List<BoxShadow> logoTile = [
    BoxShadow(color: Color(0x38FF7A5C), blurRadius: 20, offset: Offset(0, 4)),
  ];
}

/// 터치 타깃/버튼 높이.
abstract final class AppSize {
  static const touchMin = 44.0;
  static const ctaHeight = 56.0; // 주 CTA
  static const secondaryButton = 52.0; // 보조 버튼
}
