import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../services/api_client.dart';
import 'primitives.dart';
import 'sheet.dart';
import 'toast.dart';

/// 되돌리기 어려운 행동을 한 번 더 묻는 시트(탈퇴, 친구 끊기). 끝까지 해냈으면 true.
///
/// - 무엇이 일어나는지 [lines] 로 먼저 말한다. 겁주지 않고 사실만.
/// - 빨강은 쓰지 않는다(툭은 재촉하지도 겁주지도 않는 앱). 문구로 분명히 한다.
/// - [onConfirm] 이 도는 동안 버튼은 로딩, 실패하면 시트를 닫지 않고 토스트 — 다시 누를 수 있게.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirmLabel,
  required String cancelLabel,
  required Future<void> Function() onConfirm,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(
      title: title,
      lines: lines,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
    ),
  );
  return done ?? false;
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.title,
    required this.lines,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
  });

  final String title;
  final List<String> lines;
  final String confirmLabel;
  final String cancelLabel;
  final Future<void> Function() onConfirm;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTukToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill))),
          ),
          const SizedBox(height: AppSpace.x20),
          Text(widget.title, style: AppText.title20),
          const SizedBox(height: AppSpace.x16),
          for (final line in widget.lines) _Line(line),
          const SizedBox(height: AppSpace.x24),
          PillButton.primary(widget.confirmLabel, onPressed: _busy ? null : _confirm, loading: _busy),
          const SizedBox(height: AppSpace.x8),
          PillButton.secondary(widget.cancelLabel,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: AppSpace.x8),
            child: Container(width: 4, height: 4,
                decoration: const BoxDecoration(color: AppColors.textSub, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
