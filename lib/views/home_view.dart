import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/ui.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _MyCallCard(),
          const SizedBox(height: 20),
          Text('지금 한가한 친구',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (vm.loading && vm.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.friends.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                emoji: '🌙',
                text: '지금 한가한 친구가 없어요',
                hint: '친구가 콜을 켜면 여기 실시간으로 떠요',
              ),
            )
          else
            ...vm.friends.map((f) => _FriendTile(
                  name: f.nickname,
                  image: f.profileImage,
                  activity: f.activity,
                  remainingSeconds: f.remainingSeconds,
                )),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.name,
    required this.image,
    required this.activity,
    required this.remainingSeconds,
  });

  final String name;
  final String? image;
  final Activity activity;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Avatar(name: name, imageUrl: image),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${activity.emoji} ${activity.label} · ${formatRemaining(remainingSeconds)}'),
      ),
    );
  }
}

class _MyCallCard extends StatelessWidget {
  const _MyCallCard();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final me = vm.me;

    return Card(
      color: me.available ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(me.available ? '🟢' : '⚪',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    me.available
                        ? '콜 켜짐 — ${me.activity?.emoji ?? ''} ${me.activity?.label ?? ''}'
                        : '콜이 꺼져 있어요',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (me.available && me.remainingSeconds != null)
                  Text(formatRemaining(me.remainingSeconds!),
                      style: TextStyle(color: scheme.onPrimaryContainer)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              me.available
                  ? '친구들에게 내가 한가하다고 보이는 중'
                  : '콜을 켜면 친구들 홈에 내가 떠요',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (me.available)
              OutlinedButton.icon(
                onPressed: () async {
                  final err = await vm.turnOff();
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('콜 끄기'),
              )
            else
              FilledButton.icon(
                onPressed: () => _openCallSheet(context, vm),
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('콜 켜기'),
              ),
          ],
        ),
      ),
    );
  }

  void _openCallSheet(BuildContext context, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CallSheet(vm: vm),
    );
  }
}

class _CallSheet extends StatefulWidget {
  const _CallSheet({required this.vm});
  final HomeViewModel vm;

  @override
  State<_CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends State<_CallSheet> {
  Activity _activity = Activity.cafe;
  int _minutes = 60;

  static const _durations = [30, 60, 120, 180];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('무엇을 하고 싶어요?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Activity.values.map((a) {
              final sel = a == _activity;
              return ChoiceChip(
                selected: sel,
                label: Text('${a.emoji} ${a.label}'),
                onSelected: (_) => setState(() => _activity = a),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('얼마나?', style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final err = await widget.vm.turnOn(_activity, _minutes);
              if (context.mounted) {
                Navigator.of(context).pop();
                if (err != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              }
            },
            child: const Text('콜 켜기'),
          ),
        ],
      ),
    );
  }
}
