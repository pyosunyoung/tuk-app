import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../viewmodels/flash_view_model.dart';
import '../viewmodels/friend_view_model.dart';

class FlashComposeView extends StatefulWidget {
  const FlashComposeView({super.key});

  @override
  State<FlashComposeView> createState() => _FlashComposeViewState();
}

class _FlashComposeViewState extends State<FlashComposeView> {
  Activity _activity = Activity.meal;
  final _message = TextEditingController();
  final Set<int> _targets = {}; // 비어있으면 절친 전체
  int _minutes = 60;
  DateTime? _scheduledAt;
  bool _sending = false;

  static const _durations = [30, 60, 120, 180];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
      initialDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final vm = context.read<FlashViewModel>();
    final result = await vm.send(
      activity: _activity,
      message: _message.text.trim(),
      targetUserIds: _targets.isEmpty ? null : _targets.toList(),
      durationMinutes: _minutes,
      scheduledAt: _scheduledAt,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendViewModel>().friends;

    return Scaffold(
      appBar: AppBar(title: const Text('번개 보내기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('뭐 할까?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Activity.values.map((a) {
              return ChoiceChip(
                selected: a == _activity,
                label: Text('${a.emoji} ${a.label}'),
                onSelected: (_) => setState(() => _activity = a),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _message,
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '한마디 (선택)',
              hintText: '밥ㄱㄱ',
            ),
          ),
          const SizedBox(height: 12),
          Text('누구에게?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _targets.isEmpty ? '선택 안 하면 절친 전체에게 갑니다' : '${_targets.length}명 선택됨',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          if (friends.isEmpty)
            const Text('아직 친구가 없어요. 먼저 친구를 추가해보세요.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: friends.map((f) {
                final sel = _targets.contains(f.userId);
                return FilterChip(
                  selected: sel,
                  label: Text(f.nickname),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _targets.add(f.userId);
                    } else {
                      _targets.remove(f.userId);
                    }
                  }),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Text('유효 시간', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _durations.map((d) {
              return ChoiceChip(
                selected: _minutes == d,
                label: Text(d < 60 ? '$d분' : '${d ~/ 60}시간'),
                onSelected: (_) => setState(() => _minutes = d),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('예약 발송'),
            subtitle: Text(_scheduledAt == null
                ? '지금 바로 보내기'
                : '예약: ${_fmt(_scheduledAt!)}'),
            value: _scheduledAt != null,
            onChanged: (on) async {
              if (on) {
                await _pickSchedule();
              } else {
                setState(() => _scheduledAt = null);
              }
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('⚡', style: TextStyle(fontSize: 18)),
            label: Text(_scheduledAt == null ? '번개 보내기' : '예약하기'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
