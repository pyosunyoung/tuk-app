import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/activity.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';

/// '지금 한가해요' 켜기 바텀시트 (9d). 성공 시 켠 Activity 를 반환, 취소/실패 시 null.
Future<Activity?> showCallOnSheet(
  BuildContext context, {
  Activity? initialActivity,
}) {
  return showModalBottomSheet<Activity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _CallOnSheet(initialActivity: initialActivity),
  );
}

class _CallOnSheet extends StatefulWidget {
  const _CallOnSheet({this.initialActivity});
  final Activity? initialActivity;

  @override
  State<_CallOnSheet> createState() => _CallOnSheetState();
}

class _CallOnSheetState extends State<_CallOnSheet> {
  late Activity _activity;
  int _minutes = 120; // 기본 2시간
  bool _custom = false; // "직접" 선택 여부
  bool _busy = false;

  static const _presets = [60, 120, 240]; // 1 · 2 · 4시간

  @override
  void initState() {
    super.initState();
    _activity = widget.initialActivity ?? Activity.anything;
  }

  String get _durationLabel {
    final h = _minutes ~/ 60;
    final m = _minutes % 60;
    if (h == 0) return '$m분';
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final vm = context.read<PresenceViewModel>();
    final err = await vm.turnOn(_activity, _minutes);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(_activity); // 성공
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationWheel(initialMinutes: _custom ? _minutes : 210),
    );
    if (picked != null) {
      setState(() {
        _minutes = picked;
        _custom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpace.x20, 0, AppSpace.x20, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpace.x12),
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
          Text('지금 뭐 하고 싶어요?', style: AppText.title20),
          const SizedBox(height: AppSpace.x16),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: Activity.values
                .map((a) => _Chip(
                      label: a.label,
                      selected: a == _activity,
                      onTap: () => setState(() => _activity = a),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpace.x24),
          Text('얼마나 켜둘까요?',
              style: AppText.label14.copyWith(color: AppColors.textSub)),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              for (final p in _presets) ...[
                Expanded(
                  child: _DurationBox(
                    label: p < 60 ? '$p분' : '${p ~/ 60}시간',
                    selected: !_custom && _minutes == p,
                    onTap: () => setState(() {
                      _minutes = p;
                      _custom = false;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpace.x8),
              ],
              Expanded(
                child: _DurationBox(
                  label: _custom ? _durationLabel : '직접',
                  selected: _custom,
                  onTap: _pickCustom,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x24),
          PillButton.primary(
            '$_durationLabel 동안 한가해요',
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.x12),
          Center(
            child: Text('절친에게만 보여요 · $_durationLabel 뒤 자동으로 꺼져요',
                textAlign: TextAlign.center, style: AppText.caption12),
          ),
        ],
      ),
    );
  }
}

/// 활동 선택 칩 (pill).
class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: AppSpace.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: selected ? AppColors.primaryTintBorder : AppColors.border),
        ),
        child: Text(label,
            style: AppText.title16.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.primaryPress : AppColors.textSub,
            )),
      ),
    );
  }
}

/// 시간 프리셋 박스.
class _DurationBox extends StatelessWidget {
  const _DurationBox(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
              color: selected ? AppColors.primaryTintBorder : AppColors.border),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title16.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.primaryPress : AppColors.textSub,
            )),
      ),
    );
  }
}

/// 30분 단위 휠 피커 (30분~12시간).
class _DurationWheel extends StatefulWidget {
  const _DurationWheel({required this.initialMinutes});
  final int initialMinutes;

  @override
  State<_DurationWheel> createState() => _DurationWheelState();
}

class _DurationWheelState extends State<_DurationWheel> {
  // 30, 60, ... 720 (30분 간격)
  static const _step = 30;
  static const _min = 30;
  static const _max = 720;
  late int _index;

  List<int> get _values =>
      [for (int m = _min; m <= _max; m += _step) m];

  @override
  void initState() {
    super.initState();
    final v = (widget.initialMinutes ~/ _step) * _step;
    _index = _values.indexOf(v.clamp(_min, _max));
    if (_index < 0) _index = _values.indexOf(210);
  }

  String _label(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return '$m분';
    return r == 0 ? '$h시간' : '$h시간 $r분';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill)),
          ),
          const SizedBox(height: AppSpace.x20),
          Text('얼마나 켜둘까요?', style: AppText.title20),
          const SizedBox(height: AppSpace.x12),
          SizedBox(
            height: 160,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 44,
              diameterRatio: 1.4,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: _index),
              onSelectedItemChanged: (i) => setState(() => _index = i),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _values.length,
                builder: (_, i) => Center(
                  child: Text(_label(_values[i]),
                      style: AppText.title20.copyWith(
                        color: i == _index
                            ? AppColors.primaryPress
                            : AppColors.textSub,
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x20),
          PillButton.primary(
            '${_label(_values[_index])}로 설정',
            onPressed: () => Navigator.of(context).pop(_values[_index]),
          ),
        ],
      ),
    );
  }
}
