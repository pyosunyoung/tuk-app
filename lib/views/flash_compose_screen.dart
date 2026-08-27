import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/activity.dart';
import '../services/api_client.dart';
import '../viewmodels/flash_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'friend_add_sheet.dart';
import 'room_screen.dart';

/// 아래에서 위로 올라오는 전체화면 모달 라우트.
Route<void> flashComposeRoute({Activity? prefillActivity, List<int>? prefillTargetIds}) {
  return PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => FlashComposeScreen(
      prefillActivity: prefillActivity,
      prefillTargetIds: prefillTargetIds,
    ),
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: const Cubic(0.32, 0.72, 0, 1));
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

class FlashComposeScreen extends StatefulWidget {
  const FlashComposeScreen({super.key, this.prefillActivity, this.prefillTargetIds});
  final Activity? prefillActivity;
  final List<int>? prefillTargetIds;

  @override
  State<FlashComposeScreen> createState() => _FlashComposeScreenState();
}

class _FlashComposeScreenState extends State<FlashComposeScreen> {
  Activity? _activity;
  final _message = TextEditingController();
  bool _pickMode = false; // false=절친 모두, true=골라서
  final Set<int> _selected = {};
  bool _scheduled = false;
  DateTime? _scheduledAt;
  int _minutes = 60;
  bool _custom = false;
  bool _sending = false;

  static const _presets = [60, 120, 240];

  @override
  void initState() {
    super.initState();
    _activity = widget.prefillActivity;
    final pre = widget.prefillTargetIds;
    if (pre != null && pre.isNotEmpty) {
      _pickMode = true;
      _selected.addAll(pre);
    }
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final h = _minutes ~/ 60;
    final m = _minutes % 60;
    if (h == 0) return '$m분';
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  bool _canSend(List friends) {
    if (_activity == null) return false;
    if (friends.isEmpty) return false;
    if (_pickMode && _selected.isEmpty) return false;
    return true;
  }

  String _ctaLabel(List friends) {
    if (_scheduled && _scheduledAt != null) {
      return '${reservedTimeText(_scheduledAt!)}에 툭 던지기';
    }
    if (_pickMode) {
      if (_selected.length == 1) {
        final f = friends.cast<dynamic>().firstWhere((e) => e.userId == _selected.first, orElse: () => null);
        return f != null ? '${f.nickname}에게 툭 던지기' : '1명에게 툭 던지기';
      }
      return '${_selected.length}명에게 툭 던지기';
    }
    return '절친 ${friends.length}명에게 툭 던지기';
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
    var picked = DateTime(date.year, date.month, date.day, time.hour, (time.minute ~/ 15) * 15);
    if (!picked.isAfter(now)) picked = now.add(const Duration(minutes: 15));
    setState(() {
      _scheduled = true;
      _scheduledAt = picked;
    });
  }

  Future<void> _pickCustomDuration() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationWheel(initial: _custom ? _minutes : 210),
    );
    if (picked != null) setState(() { _minutes = picked; _custom = true; });
  }

  Future<void> _send(List friends) async {
    setState(() => _sending = true);
    final vm = context.read<FlashViewModel>();
    try {
      final created = await vm.send(
        activity: _activity!,
        message: _message.text.trim(),
        targetUserIds: _pickMode ? _selected.toList() : <int>[],
        durationMinutes: _minutes,
        scheduledAt: _scheduled ? _scheduledAt : null,
      );
      if (!mounted) return;
      vm.reloadSent(); // 홈 "내가 띄운 번개" 배너 갱신
      if (_scheduled && _scheduledAt != null) {
        // 예약 → 홈으로 닫고 토스트
        Navigator.of(context).pop();
        showTukToast(context, '${reservedTimeText(_scheduledAt!)}에 전해질 거예요');
        return;
      }
      // 지금 → 모임방으로 replace + 토스트
      final toast = _sendToast(created.recipientCount, friends);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => RoomScreen(
          flashId: created.flashId,
          expiresAt: created.expiresAt,
          initialToast: toast,
        ),
      ));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showTukToast(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        showTukToast(context, '잠시 후 다시 시도해 주세요');
      }
    }
  }

  String _sendToast(int count, List friends) {
    if (count == 0) return '지금 받을 절친이 없어요 · 방은 열어뒀어요';
    if (_pickMode && _selected.length == 1) {
      final f = friends.cast<dynamic>().firstWhere((e) => e.userId == _selected.first, orElse: () => null);
      if (f != null) return '${f.nickname}에게 툭을 던졌어요';
    }
    return '절친 $count명에게 툭을 던졌어요';
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendViewModel>().friends;
    final canSend = _canSend(friends);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpace.x20, right: AppSpace.x20, top: AppSpace.x8, bottom: AppSpace.x12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                        width: 36, height: 36,
                        child: Icon(Icons.close, size: 22, color: AppColors.text)),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Text('툭 띄우기', style: AppText.title20),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpace.x20, 0, AppSpace.x20, 120),
                    children: [
                      _label('뭐 하고 놀까요?'),
                      const SizedBox(height: AppSpace.x12),
                      _activityChips(),
                      const SizedBox(height: AppSpace.x24),
                      _messageField(),
                      const SizedBox(height: AppSpace.x24),
                      _label('누구에게 던질까요?'),
                      const SizedBox(height: AppSpace.x12),
                      if (friends.isEmpty) _noFriends() else _targetSection(friends),
                      const SizedBox(height: AppSpace.x24),
                      _label('언제 · 얼마나'),
                      const SizedBox(height: AppSpace.x12),
                      _whenRow(),
                      const SizedBox(height: AppSpace.x8),
                      _durationRow(),
                    ],
                  ),
                  _bottomCta(canSend, friends),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: AppSpace.x4),
        child: Text(t, style: AppText.label14.copyWith(color: AppColors.textSub)),
      );

  Widget _activityChips() {
    return Wrap(
      spacing: AppSpace.x8,
      runSpacing: AppSpace.x8,
      children: Activity.values.map((a) => _Chip(
            label: a.label,
            selected: a == _activity,
            onTap: () => setState(() => _activity = a),
          )).toList(),
    );
  }

  Widget _messageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpace.x16),
          child: TextField(
            controller: _message,
            maxLength: 200,
            maxLines: 4,
            minLines: 1,
            style: AppText.body,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
              hintText: '한마디 남길래요? (선택)',
              hintStyle: TextStyle(
                  fontFamily: 'Pretendard', fontSize: 16, color: AppColors.textSub),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x8),
        Text('${_message.text.characters.length} / 200', style: AppText.caption12),
      ],
    );
  }

  Widget _noFriends() {
    return Row(
      children: [
        Expanded(
          child: Text('먼저 절친을 추가해 주세요',
              style: AppText.label14.copyWith(color: AppColors.textSub)),
        ),
        const SizedBox(width: AppSpace.x8),
        GestureDetector(
          onTap: () => showFriendAddSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('친구 추가',
                style: AppText.label15.copyWith(color: AppColors.textSub)),
          ),
        ),
      ],
    );
  }

  Widget _targetSection(List friends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Segment('절친 모두', !_pickMode, () => setState(() => _pickMode = false))),
            const SizedBox(width: AppSpace.x8),
            Expanded(child: _Segment('골라서', _pickMode, () => setState(() => _pickMode = true))),
          ],
        ),
        const SizedBox(height: AppSpace.x12),
        if (!_pickMode)
          Row(
            children: [
              _AvatarStack(friends: friends),
              const SizedBox(width: AppSpace.x10),
              Text('절친 ${friends.length}명에게 갈 거예요', style: AppText.caption13),
            ],
          )
        else
          Column(
            children: friends.map<Widget>((f) {
              final on = _selected.contains(f.userId);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x8),
                child: _FriendPick(
                  nickname: f.nickname,
                  imageUrl: f.profileImage,
                  selected: on,
                  onTap: () => setState(() {
                    if (on) {
                      _selected.remove(f.userId);
                    } else {
                      _selected.add(f.userId);
                    }
                  }),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _whenRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Segment('지금', !_scheduled, () => setState(() { _scheduled = false; _scheduledAt = null; }))),
            const SizedBox(width: AppSpace.x8),
            Expanded(child: _Segment(
              _scheduled && _scheduledAt != null ? reservedTimeText(_scheduledAt!) : '예약',
              _scheduled,
              _pickSchedule,
            )),
          ],
        ),
      ],
    );
  }

  Widget _durationRow() {
    return Row(
      children: [
        for (final p in _presets) ...[
          Expanded(child: _Segment(
            p < 60 ? '$p분' : '${p ~/ 60}시간',
            !_custom && _minutes == p,
            () => setState(() { _minutes = p; _custom = false; }),
          )),
          const SizedBox(width: AppSpace.x8),
        ],
        Expanded(child: _Segment(
          _custom ? _durationLabel : '직접',
          _custom,
          _pickCustomDuration,
        )),
      ],
    );
  }

  Widget _bottomCta(bool canSend, List friends) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x16, AppSpace.x20, 46),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [AppColors.background, Color(0x00FBF7F1)], stops: [0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PillButton.primary(
              _ctaLabel(friends),
              loading: _sending,
              onPressed: canSend ? () => _send(friends) : null,
            ),
            const SizedBox(height: AppSpace.x12),
            Text('무시해도 상대에겐 아무것도 안 보여요 · $_durationLabel 뒤 끝나요',
                textAlign: TextAlign.center, style: AppText.caption12),
          ],
        ),
      ),
    );
  }
}

// ─────────── 공용 소형 위젯 (발송 화면 전용)

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
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
          border: Border.all(color: selected ? AppColors.primaryTintBorder : AppColors.border),
        ),
        child: Text(label, style: AppText.title16.copyWith(
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.primaryPress : AppColors.textSub)),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: selected ? AppColors.primaryTintBorder : AppColors.border),
        ),
        child: Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppText.label15.copyWith(
                color: selected ? AppColors.primaryPress : AppColors.textSub)),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.friends});
  final List friends;
  @override
  Widget build(BuildContext context) {
    final show = friends.take(5).toList();
    final extra = friends.length - show.length;
    return SizedBox(
      height: 28,
      width: show.length * 20.0 + 8 + (extra > 0 ? 20 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.background, width: 2))),
                child: InitialAvatar(nickname: show[i].nickname, imageUrl: show[i].profileImage, size: 28),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: show.length * 20.0,
              child: Container(
                width: 28, height: 28, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text('+$extra', style: AppText.caption12.copyWith(
                    color: AppColors.primaryPress, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendPick extends StatelessWidget {
  const _FriendPick({required this.nickname, this.imageUrl, required this.selected, required this.onTap});
  final String nickname;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            InitialAvatar(nickname: nickname, imageUrl: imageUrl),
            const SizedBox(width: AppSpace.x12),
            Expanded(child: Text(nickname, overflow: TextOverflow.ellipsis,
                style: AppText.label15.copyWith(fontWeight: FontWeight.w600))),
            Container(
              width: 24, height: 24, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: AppColors.border),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationWheel extends StatefulWidget {
  const _DurationWheel({required this.initial});
  final int initial;
  @override
  State<_DurationWheel> createState() => _DurationWheelState();
}

class _DurationWheelState extends State<_DurationWheel> {
  static const _step = 30, _min = 30, _max = 720;
  late int _index;
  List<int> get _values => [for (int m = _min; m <= _max; m += _step) m];
  @override
  void initState() {
    super.initState();
    final v = ((widget.initial ~/ _step) * _step).clamp(_min, _max);
    _index = _values.indexOf(v);
    if (_index < 0) _index = _values.indexOf(210);
  }
  String _label(int m) {
    final h = m ~/ 60, r = m % 60;
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
      padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill))),
          const SizedBox(height: AppSpace.x20),
          Text('얼마나 열어둘까요?', style: AppText.title20),
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
                builder: (_, i) => Center(child: Text(_label(_values[i]),
                    style: AppText.title20.copyWith(
                        color: i == _index ? AppColors.primaryPress : AppColors.textSub))),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x20),
          PillButton.primary('${_label(_values[_index])}로 설정',
              onPressed: () => Navigator.of(context).pop(_values[_index])),
        ],
      ),
    );
  }
}
