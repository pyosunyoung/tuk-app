import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meetup_room.dart';
import '../services/api_client.dart';
import '../viewmodels/flash_view_model.dart';
import '../widgets/ui.dart';

/// 모임방 — 멤버(합류자) + 장소. MEMBER_JOINED 실시간 반영.
class RoomView extends StatefulWidget {
  const RoomView({super.key, required this.flashId});
  final int flashId;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  MeetupRoom? _room;
  bool _loading = true;
  String? _error;
  late final FlashViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<FlashViewModel>();
    // flash 실시간 이벤트(MEMBER_JOINED 등)로 VM 이 갱신되면 방을 새로고침.
    _vm.addListener(_onVmChanged);
    _load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    if (mounted) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final room = await _vm.room(widget.flashId);
      if (mounted) {
        setState(() {
          _room = room;
          _loading = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임방'),
        actions: [
          IconButton(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _room == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _room == null) {
      return EmptyState(emoji: '😵', text: _error!);
    }
    final room = _room!;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Text(room.activity.emoji,
                  style: const TextStyle(fontSize: 28)),
              title: Text('${room.activity.label} 번개',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(room.status == 'OPEN' ? '진행 중' : '종료됨'),
            ),
          ),
          const SizedBox(height: 16),

          // 장소
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_outlined, color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text('장소',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(room.placeName ?? '아직 장소가 정해지지 않았어요',
                      style: TextStyle(
                        color: room.hasPlace ? null : scheme.outline,
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _editPlace(room),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Text(room.hasPlace ? '장소 변경' : '장소 정하기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('참여자 (${room.members.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...room.members.map((m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Avatar(name: m.nickname, imageUrl: m.profileImage),
                  title: Text(m.nickname),
                  trailing: m.sender
                      ? Chip(
                          label: const Text('보낸이'),
                          backgroundColor: scheme.primaryContainer,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _editPlace(MeetupRoom room) async {
    final controller = TextEditingController(text: room.placeName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('장소 정하기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 홍대 A카페'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final updated = await _vm.setPlace(widget.flashId, placeName: name);
      if (mounted) setState(() => _room = updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
