import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';

enum _PillKind { primary, kakao, secondary }

/// 공용 pill 버튼. 눌림 = scale 0.98 + 배경 전환(120ms), 바운스 없음.
class PillButton extends StatefulWidget {
  // private named 필드라 this._kind 초기화 형식을 못 써서 : 초기화 사용
  const PillButton._({
    required _PillKind kind,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leading,
  }) : _kind = kind;

  /// 주 CTA — 코랄 배경 + 흰 글자, 높이 56, 코랄 그림자.
  factory PillButton.primary(
    String label, {
    required VoidCallback? onPressed,
    bool loading = false,
  }) =>
      PillButton._(
        kind: _PillKind.primary,
        label: label,
        onPressed: onPressed,
        loading: loading,
      );

  /// 카카오 — 노란 배경 + 어두운 글자, 높이 56. leading = 카카오 로고 자리.
  factory PillButton.kakao(
    String label, {
    required VoidCallback? onPressed,
    bool loading = false,
    Widget? leading,
  }) =>
      PillButton._(
        kind: _PillKind.kakao,
        label: label,
        onPressed: onPressed,
        loading: loading,
        leading: leading,
      );

  /// 보조 — 흰 배경 + 테두리, 높이 52.
  factory PillButton.secondary(
    String label, {
    required VoidCallback? onPressed,
  }) =>
      PillButton._(
        kind: _PillKind.secondary,
        label: label,
        onPressed: onPressed,
      );

  final _PillKind _kind;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? leading;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  double get _height =>
      widget._kind == _PillKind.secondary ? AppSize.secondaryButton : AppSize.ctaHeight;

  Color get _bg {
    switch (widget._kind) {
      case _PillKind.primary:
        return _pressed ? AppColors.primaryPress : AppColors.primary;
      case _PillKind.kakao:
        return AppColors.kakao;
      case _PillKind.secondary:
        return AppColors.surface;
    }
  }

  Color get _fg => switch (widget._kind) {
        _PillKind.primary => Colors.white,
        _PillKind.kakao => AppColors.text,
        _PillKind.secondary => AppColors.textSub,
      };

  @override
  Widget build(BuildContext context) {
    final content = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_fg),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: AppSpace.x10),
              ],
              Text(
                widget.label,
                style: (widget._kind == _PillKind.secondary
                        ? AppText.label15
                        : AppText.title16)
                    .copyWith(color: _fg),
              ),
            ],
          );

    return Opacity(
      opacity: _enabled ? 1 : 0.6,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: widget._kind == _PillKind.secondary
                  ? Border.all(color: AppColors.border)
                  : null,
              boxShadow:
                  widget._kind == _PillKind.primary ? AppShadow.coralCta : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// 랜딩·인트로의 요약 카드 한 줄 — 6×6 코랄 점 + 텍스트.
class SummaryCard extends StatelessWidget {
  const SummaryCard(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.x10),
          Expanded(
            child: Text(text, style: AppText.label15),
          ),
        ],
      ),
    );
  }
}
