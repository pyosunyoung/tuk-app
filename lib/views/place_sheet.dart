import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../widgets/primitives.dart';

/// 장소 정하기 시트 (11e). 저장한 placeName 을 반환, 취소 시 null.
/// 지도·검색은 범위 밖 — placeName 자유 입력만.
Future<String?> showPlaceSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _PlaceSheet(current: current),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({this.current});
  final String? current;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current ?? '');
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      if (widget.current != null && widget.current!.isNotEmpty) {
        _controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _ready => _controller.text.trim().isNotEmpty;
  bool get _editing => widget.current != null && widget.current!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill))),
            ),
            const SizedBox(height: AppSpace.x20),
            Text('어디서 볼까요?', style: AppText.title20),
            const SizedBox(height: AppSpace.x20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: _focus.hasFocus ? AppColors.primary : AppColors.border),
              ),
              padding: const EdgeInsets.all(AppSpace.x16),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                maxLength: 60,
                style: AppText.body,
                onSubmitted: (_) { if (_ready) Navigator.of(context).pop(_controller.text.trim()); },
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: '가게 이름이나 만날 곳',
                  hintStyle: TextStyle(
                      fontFamily: 'Pretendard', fontSize: 16, color: AppColors.textSub),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_controller.text.characters.length} / 60', style: AppText.caption12),
            ),
            const SizedBox(height: AppSpace.x8),
            PillButton.primary(
              _editing ? '장소 바꾸기' : '장소 정하기',
              onPressed: _ready ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
            ),
            const SizedBox(height: AppSpace.x16),
            Center(
              child: Text('모인 사람 모두에게 보여요 · 나중에 바꿀 수 있어요',
                  style: AppText.caption12),
            ),
          ],
        ),
      ),
    );
  }
}
