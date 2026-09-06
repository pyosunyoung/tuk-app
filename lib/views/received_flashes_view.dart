import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flash.dart';
import '../services/api_client.dart';
import '../viewmodels/flash_view_model.dart';
import '../widgets/ui.dart';
import 'room_view.dart';

class ReceivedFlashesView extends StatelessWidget {
  const ReceivedFlashesView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FlashViewModel>();

    return RefreshIndicator(
      onRefresh: vm.loadReceived,
      child: (vm.received.isEmpty && !vm.loading)
          ? ListView(
              // RefreshIndicator 가 동작하려면 스크롤 가능해야 함
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  emoji: '⚡',
                  text: '받은 번개가 없어요',
                  hint: '친구가 번개를 보내면 여기로 와요',
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.loading && vm.received.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ...vm.received.map((f) => _FlashCard(flash: f)),
              ],
            ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.flash});
  final ReceivedFlash flash;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: flash.senderNickname, imageUrl: flash.senderProfileImage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flash.senderNickname,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${flash.activity.emoji} ${flash.activity.label}',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (flash.joined)
                  Chip(
                    label: const Text('합류함'),
                    backgroundColor: scheme.secondaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (flash.message != null && flash.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(flash.message!, style: const TextStyle(fontSize: 15)),
            ],
            if (flash.scheduledAt != null) ...[
              const SizedBox(height: 8),
              Text('예약: ${_fmt(flash.scheduledAt!)}',
                  style: TextStyle(color: scheme.outline, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: flash.joined
                  ? OutlinedButton.icon(
                      onPressed: () => _openRoom(context, flash.flashId),
                      icon: const Icon(Icons.meeting_room_outlined),
                      label: const Text('모임방 열기'),
                    )
                  : FilledButton.icon(
                      onPressed: () => _join(context, flash.flashId),
                      icon: const Text('⚡', style: TextStyle(fontSize: 16)),
                      label: const Text('합류하기'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join(BuildContext context, int flashId) async {
    final vm = context.read<FlashViewModel>();
    try {
      final room = await vm.join(flashId);
      if (room != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RoomView(flashId: flashId)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _openRoom(BuildContext context, int flashId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomView(flashId: flashId)),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
