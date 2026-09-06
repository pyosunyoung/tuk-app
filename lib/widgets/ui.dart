import 'package:flutter/material.dart';

/// 남은 초 → "1시간 20분" / "5분" 형태.
String formatRemaining(int seconds) {
  if (seconds <= 0) return '곧 만료';
  final m = (seconds / 60).ceil();
  if (m < 60) return '$m분 남음';
  final h = m ~/ 60;
  final rem = m % 60;
  return rem == 0 ? '$h시간 남음' : '$h시간 $rem분 남음';
}

/// 원형 아바타 — profileImage 있으면 네트워크, 없으면 이니셜.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.imageUrl, required this.name, this.radius = 22});

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(initial,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}

/// 리스트 비었을 때 안내.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.text, this.hint});

  final String emoji;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ],
        ),
      ),
    );
  }
}
