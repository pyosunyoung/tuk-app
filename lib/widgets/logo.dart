import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// 툭 로고 변형.
enum TukLogoVariant {
  /// 코랄 타일 + 흰 글자/획 (기본)
  coral,

  /// 밝은 배경용: 틴트 타일 + 코랄 글자/획
  light,

  /// 스플래시(코랄 전면) 위: 반투명 흰 타일 + 흰 글자/획
  splashTile,
}

/// 툭 앱 로고 — 코랄 타일 안에 '툭'을 좌하단 정렬하고 던지는 궤적을 얹는다.
/// 모든 형태는 viewBox 120 기준으로 정의하고 [size] 로 균일 확대/축소한다.
/// (획·점만은 작아질수록 상대적으로 굵게 — 핸드오프 규칙)
class TukLogo extends StatelessWidget {
  const TukLogo({
    super.key,
    this.size = 80,
    this.variant = TukLogoVariant.coral,
  });

  final double size;
  final TukLogoVariant variant;

  // 타일 반경: 변 길이의 약 23~25%. 핸드오프 예: 120→28, 80→20, 72→18, 96→24.
  double get _radius => size * (28 / 120);

  Color get _tileColor => switch (variant) {
        TukLogoVariant.coral => AppColors.primary,
        TukLogoVariant.light => AppColors.primaryTint,
        TukLogoVariant.splashTile => Colors.white.withValues(alpha: 0.14),
      };

  Color get _inkColor => switch (variant) {
        TukLogoVariant.coral => Colors.white,
        TukLogoVariant.light => AppColors.primary,
        TukLogoVariant.splashTile => Colors.white,
      };

  double get _thickOpacity => variant == TukLogoVariant.light ? 0.45 : 0.5;

  @override
  Widget build(BuildContext context) {
    final scale = size / 120.0;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: _tileColor)),
            Positioned.fill(
              child: CustomPaint(
                painter: _TrajectoryPainter(
                  size: size,
                  ink: _inkColor,
                  thickOpacity: _thickOpacity,
                ),
              ),
            ),
            // '툭' 좌하단. viewBox 기준 fontSize 52, padding 좌16·하14.
            Positioned(
              left: 16 * scale,
              bottom: 14 * scale,
              child: Text(
                '툭',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 52 * scale,
                  height: 0.9,
                  letterSpacing: -3 * scale,
                  color: _inkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({
    required this.size,
    required this.ink,
    required this.thickOpacity,
  });

  final double size;
  final Color ink;
  final double thickOpacity;

  // 크기별 획/점 굵기(viewBox 120 단위). 작아질수록 상대적으로 굵게.
  double get _thickStroke {
    if (size >= 100) return 7;
    if (size >= 72) return 8;
    if (size >= 48) return 9;
    if (size >= 32) return 10;
    return 13;
  }

  double? get _faintStroke => size >= 72 ? 3 : null; // 56 이하 생략
  double get _dotRadius {
    if (size >= 100) return 8;
    if (size >= 72) return 8.5;
    if (size >= 48) return 9.5;
    if (size >= 32) return 10;
    return 11.5;
  }

  @override
  void paint(Canvas canvas, Size s) {
    final scale = s.width / 120.0;
    canvas.scale(scale);

    // 굵은 궤적: M28 44 c22-16 46-18 66-8
    final thick = Path()
      ..moveTo(28, 44)
      ..cubicTo(50, 28, 74, 26, 94, 36);
    canvas.drawPath(
      thick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _thickStroke
        ..color = ink.withValues(alpha: thickOpacity),
    );

    // 흐린 궤적: M40 36 c18-8 36-8 52-2 (작은 크기에선 생략)
    final faint = _faintStroke;
    if (faint != null) {
      final path = Path()
        ..moveTo(40, 36)
        ..cubicTo(58, 28, 76, 28, 92, 34);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = faint
          ..color = ink.withValues(alpha: 0.22),
      );
    }

    // 끝점: circle (96,36) — 항상 accent 노란색
    canvas.drawCircle(
      const Offset(96, 36),
      _dotRadius,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(_TrajectoryPainter old) =>
      old.size != size || old.ink != ink || old.thickOpacity != thickOpacity;
}
