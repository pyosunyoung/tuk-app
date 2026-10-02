import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../services/update_checker.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';

/// "새 버전이 나왔어요". 받을 곳이 있으면 버튼으로, 없으면(카톡으로 나눠주는 동안) 어디서 받는지 말로.
Future<void> showUpdateSheet(BuildContext context, PendingUpdate update) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _UpdateSheet(update),
  );
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet(this.update);
  final PendingUpdate update;

  @override
  Widget build(BuildContext context) {
    final info = update.info;
    final url = info.downloadUrl;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4))],
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
          Text('새 버전이 나왔어요 (${info.latestVersion})', style: AppText.title20),
          const SizedBox(height: AppSpace.x8),
          if (update.required)
            Text('지금 버전으로는 일부 기능이 제대로 안 될 수 있어요.', style: AppText.body),
          if (info.notes != null && info.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x8),
            Text(info.notes!, style: AppText.body.copyWith(color: AppColors.textSub)),
          ],
          const SizedBox(height: AppSpace.x8),
          if (url == null)
            Text('툭을 나눠준 친구나 단톡방에서 새 설치 파일을 받아 설치해 주세요. 지금 쓰던 내용은 그대로 남아요.',
                style: AppText.caption13),
          const SizedBox(height: AppSpace.x24),
          if (url != null) ...[
            PillButton.primary('받으러 가기', onPressed: () {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              Navigator.of(context).pop();
            }),
            const SizedBox(height: AppSpace.x8),
            PillButton.secondary('나중에', onPressed: () => Navigator.of(context).pop()),
          ] else
            PillButton.primary('확인', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
