import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';
import '../core/keep_words.dart';

/// 약속 시간 정하기 시트. 고른 시각을 반환, 닫으면 null.
///
/// **조율하는 화면이 아니라 기록하는 화면이다.** 시간대 투표나 후보 여러 개를 두지 않는다 —
/// 언제 만날지 맞추는 건 카톡이 훨씬 잘하고(그래서 모임방에 "카톡으로 이야기하기"가 있다),
/// 여기는 정해진 결론을 적어두고 나중에 까먹었을 때 다시 보는 자리다.
///
/// 그래서 선택지는 지금부터 30분 단위로만 준다. 서버가 받는 범위(과거 1시간 ~ 미래 24시간)
/// 안쪽으로만 만들어서, 고를 수 있는 건 전부 저장도 된다.
Future<DateTime?> showMeetTimeSheet(BuildContext context, {DateTime? current}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _MeetTimeSheet(current: current),
  );
}

/// 지금 이후 30분 단위 후보. 다음 30분 경계부터 12시간치.
List<DateTime> meetTimeOptions(DateTime now) {
  final firstMinute = now.minute < 30 ? 30 : 60;
  var slot = DateTime(now.year, now.month, now.day, now.hour).add(Duration(minutes: firstMinute));
  return [for (var i = 0; i < 24; i++) slot.add(Duration(minutes: 30 * i))];
}

/// "오늘 오후 8시" / "오늘 오후 8시 30분" / 날짜가 넘어가면 "내일 …"
String meetTimeLabel(DateTime when, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final isTomorrow = DateTime(when.year, when.month, when.day)
      .isAfter(DateTime(today.year, today.month, today.day));
  final ampm = when.hour < 12 ? '오전' : '오후';
  final h12 = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final minute = when.minute == 0 ? '' : ' ${when.minute}분';
  return '${isTomorrow ? '내일' : '오늘'} $ampm $h12시$minute';
}

class _MeetTimeSheet extends StatefulWidget {
  const _MeetTimeSheet({this.current});
  final DateTime? current;

  @override
  State<_MeetTimeSheet> createState() => _MeetTimeSheetState();
}

class _MeetTimeSheetState extends State<_MeetTimeSheet> {
  /// 행 높이를 고정해야 선택된 항목으로 정확히 스크롤할 수 있다.
  static const _rowHeight = 72.0;

  late final List<DateTime> _options = meetTimeOptions(DateTime.now());
  late DateTime _selected = _initial();
  late final ScrollController _scroll = ScrollController(
    // 고른 시간이 화면 밖에 있으면 "왜 이 시간이지?" 가 된다 — 열자마자 보이게 맞춰 연다.
    initialScrollOffset: _options.indexOf(_selected) * _rowHeight,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 이미 정해진 시간이 있으면 그 근처에서 시작한다.
  DateTime _initial() {
    final current = widget.current;
    if (current == null) return _options.first;
    return _options.firstWhere(
      (o) => !o.isBefore(current),
      orElse: () => _options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          const SizedBox(height: AppSpace.x20),
          Text(keepWords('언제 만날까요?'), style: AppText.title20),
          const SizedBox(height: AppSpace.x4),
          Text(keepWords('정하기 어려우면 카톡으로 이야기하고 와서 적어도 돼요'),
              style: AppText.label14.copyWith(color: AppColors.textSub)),
          const SizedBox(height: AppSpace.x16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _rowHeight,
              itemCount: _options.length,
              itemBuilder: (_, i) => _TimeRow(
                label: meetTimeLabel(_options[i]),
                selected: _options[i] == _selected,
                onTap: () => setState(() => _selected = _options[i]),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x20),
          PillButton.primary(
            '${meetTimeLabel(_selected)}로 정하기',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
          const SizedBox(height: AppSpace.x12),
          Center(
            child: Text(keepWords('모인 사람 모두에게 보여요 · 나중에 바꿀 수 있어요'),
                style: AppText.caption12),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
        margin: const EdgeInsets.only(bottom: AppSpace.x8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(keepWords(
                label),
                style: AppText.body.copyWith(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
