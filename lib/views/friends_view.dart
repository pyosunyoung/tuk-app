import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/friend_view_model.dart';
import '../widgets/ui.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendViewModel>();

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InviteCard(vm: vm),
          const SizedBox(height: 20),
          if (vm.requests.isNotEmpty) ...[
            Text('받은 신청 (${vm.requests.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...vm.requests.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Avatar(name: r.nickname, imageUrl: r.profileImage),
                    title: Text(r.nickname),
                    trailing: FilledButton(
                      onPressed: () async {
                        final err = await vm.accept(r.friendshipId);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(err)));
                        }
                      },
                      child: const Text('수락'),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          Text('내 친구 (${vm.friends.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (vm.loading && vm.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: EmptyState(
                emoji: '🤝',
                text: '아직 친구가 없어요',
                hint: '초대코드를 공유하거나 친구 코드를 입력해보세요',
              ),
            )
          else
            ...vm.friends.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Avatar(name: f.nickname, imageUrl: f.profileImage),
                    title: Text(f.nickname),
                  ),
                )),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.vm});
  final FriendViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('친구 추가',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('서로 초대코드를 주고받아 절친이 됩니다.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMyCode(context),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('내 코드'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _enterCode(context),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('코드 입력'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyCode(BuildContext context) async {
    await vm.ensureInviteCode();
    if (!context.mounted) return;
    final code = vm.inviteCode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('내 초대코드'),
        content: code == null
            ? const Text('초대코드를 불러오지 못했어요.\n백엔드 초대코드 API가 배포됐는지 확인해주세요.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    code,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4),
                  ),
                  const SizedBox(height: 8),
                  const Text('이 코드를 친구에게 알려주세요.'),
                ],
              ),
        actions: [
          if (code != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('코드를 복사했어요')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('복사'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기')),
        ],
      ),
    );
  }

  Future<void> _enterCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('친구 코드 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: '친구에게 받은 코드',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
    final result = await vm.redeem(code);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}
