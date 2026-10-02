import 'package:flutter/material.dart';

import '../core/map_links.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../widgets/sheet.dart';
import '../core/keep_words.dart';

/// 지도 앱 고르기 시트. 고른 앱을 반환, 닫으면 null.
/// 마지막으로 쓴 앱을 위에 두고 '최근' 표시 — 매번 같은 앱을 쓰는 사람은 한 번에 누른다.
Future<MapApp?> showMapAppSheet(
  BuildContext context, {
  required String placeName,
  MapApp? lastUsed,
}) {
  return showModalBottomSheet<MapApp>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _MapAppSheet(placeName: placeName, lastUsed: lastUsed),
  );
}

class _MapAppSheet extends StatelessWidget {
  const _MapAppSheet({required this.placeName, this.lastUsed});
  final String placeName;
  final MapApp? lastUsed;

  @override
  Widget build(BuildContext context) {
    final apps = [...MapApp.values]
      ..sort((a, b) => a == lastUsed ? -1 : (b == lastUsed ? 1 : 0));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill))),
          ),
          const SizedBox(height: AppSpace.x20),
          Text(keepWords('어느 지도로 볼까요?'), style: AppText.title20),
          const SizedBox(height: AppSpace.x4),
          Text(keepWords(placeName),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption13),
          const SizedBox(height: AppSpace.x20),
          for (final app in apps) ...[
            _AppRow(
              app: app,
              recent: app == lastUsed,
              onTap: () => Navigator.of(context).pop(app),
            ),
            const SizedBox(height: AppSpace.x8),
          ],
          const SizedBox(height: AppSpace.x8),
          Center(child: Text(keepWords('앱이 없으면 웹 지도로 열려요'), style: AppText.caption12)),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.recent, required this.onTap});
  final MapApp app;
  final bool recent;
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
            color: recent ? AppColors.primaryTint : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: recent ? AppColors.primaryTintBorder : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.map_outlined, size: 22,
                  color: recent ? AppColors.primaryPress : AppColors.textSub),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text(keepWords(app.label),
                    style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (recent)
                Text(keepWords('최근'), style: AppText.caption12.copyWith(
                    color: AppColors.primaryPress, fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpace.x4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
            ],
          ),
        ),
      ),
    );
  }
}
