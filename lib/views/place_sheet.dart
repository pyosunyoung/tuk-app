import 'dart:async';

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/place.dart';
import '../widgets/sheet.dart';

/// 장소 정하기 시트 (11e). 고른 [Place] 를 반환, 닫으면 null.
///
/// 입력하면 카카오 장소 검색 결과가 뜨고, 고르면 그 실제 장소(좌표·주소·카카오 ID)가 저장된다.
/// 손으로 쓰면 오타 하나로 약속이 틀어지지만, 검색에서 고르면 "그 장소"가 확실하다.
/// 검색에 안 나오는 곳("학교 정문")은 맨 아래 "그대로 쓰기"로 직접 입력한다 — 검색이 안 될 때도 이 길은 항상 열려 있다.
Future<Place?> showPlaceSheet(
  BuildContext context, {
  String? current,
  required Future<List<Place>> Function(String query) search,
}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _PlaceSheet(current: current, search: search),
  );
}

enum _Phase { idle, loading, done, failed }

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({this.current, required this.search});
  final String? current;
  final Future<List<Place>> Function(String query) search;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  static const _debounce = Duration(milliseconds: 350);

  late final TextEditingController _controller;
  final _focus = FocusNode();
  Timer? _timer;

  _Phase _phase = _Phase.idle;
  List<Place> _results = const [];

  /// 늦게 도착한 옛 검색 응답이 최신 결과를 덮지 않도록 요청마다 번호를 붙인다.
  int _seq = 0;
  String _lastText = '';

  String get _query => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current ?? '');
    _lastText = _controller.text;
    _controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      if (_query.isNotEmpty) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        _runSearch(); // 장소를 바꾸는 경우: 지금 장소로 먼저 찾아 둔다
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    // 커서 이동·선택 변경에도 리스너가 불린다 → 글자가 바뀐 경우만
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    _timer?.cancel();
    if (_query.isEmpty) {
      _seq++;
      setState(() {
        _phase = _Phase.idle;
        _results = const [];
      });
      return;
    }
    setState(() {}); // "그대로 쓰기" 줄 갱신
    _timer = Timer(_debounce, _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _query;
    if (query.isEmpty) return;
    final seq = ++_seq;
    setState(() => _phase = _Phase.loading);
    try {
      final results = await widget.search(query);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = results;
        _phase = _Phase.done;
      });
    } catch (_) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = const [];
        _phase = _Phase.failed;
      });
    }
  }

  void _pick(Place place) => Navigator.of(context).pop(place);

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // 키보드 위 남은 공간의 대부분을 쓴다(결과 목록이 보이도록)
    final height = (MediaQuery.sizeOf(context).height - keyboard) * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill))),
            ),
            const SizedBox(height: AppSpace.x20),
            Text('어디서 볼까요?', style: AppText.title20),
            const SizedBox(height: AppSpace.x16),
            _searchField(),
            const SizedBox(height: AppSpace.x12),
            Expanded(child: _body()),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x8),
              _ManualRow(text: _query, onTap: () => _pick(Place.manual(_query))),
            ],
            const SizedBox(height: AppSpace.x12),
            Center(
              child: Text('모인 사람 모두에게 보여요 · 나중에 바꿀 수 있어요',
                  style: AppText.caption12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: _focus.hasFocus ? AppColors.primary : AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.textSub),
          const SizedBox(width: AppSpace.x8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              maxLength: 60,
              style: AppText.body,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _timer?.cancel();
                _runSearch();
              },
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '가게나 장소 이름으로 검색',
                hintStyle: TextStyle(
                    fontFamily: 'Pretendard', fontSize: 16, color: AppColors.textSub),
              ),
            ),
          ),
          if (_phase == _Phase.loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_query.isEmpty) {
      return const _Hint(
        title: '예: 강남역 스타벅스, 홍대입구역 9번 출구',
        body: '검색해서 고르면 지도에서 정확히 그 장소가 열려요',
      );
    }
    if (_phase == _Phase.failed) {
      return const _Hint(
        title: '지금은 검색이 안 돼요',
        body: '아래 "그대로 쓰기"로 입력한 이름을 쓸 수 있어요',
      );
    }
    if (_phase == _Phase.done && _results.isEmpty) {
      return const _Hint(
        title: '검색 결과가 없어요',
        body: '학교 정문처럼 검색에 없는 곳은 아래 "그대로 쓰기"로 정해요',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, thickness: 1, color: AppColors.border),
      itemBuilder: (_, i) => _ResultRow(place: _results[i], onTap: () => _pick(_results[i])),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpace.x4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.place_outlined, size: 20, color: AppColors.primaryPress),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (place.category != null) ...[
                        const SizedBox(width: AppSpace.x8),
                        Text(place.category!, style: AppText.caption12),
                      ],
                    ],
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 2),
                    Text(place.address!,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption13),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 직접 입력 — 검색에 없는 곳, 검색이 안 될 때의 탈출구.
class _ManualRow extends StatelessWidget {
  const _ManualRow({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSub),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '"$text"',
                        style: AppText.label14.copyWith(fontWeight: FontWeight.w600)),
                    TextSpan(text: ' 그대로 쓰기', style: AppText.label14),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.label14
                  .copyWith(color: AppColors.textSub, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpace.x4),
          Text(body, style: AppText.caption13),
        ],
      ),
    );
  }
}
