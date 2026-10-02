import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';

/// 의견 보내기. 친구들이 실제로 쓰기 시작하면 "이상해요"를 알려줄 길이 있어야 한다.
///
/// 메일 앱이 없거나 안 열리는 폰이 있어 주소 복사를 같이 둔다.
/// 메일 본문에 앱 버전·기기를 미리 채운다 — "어떤 폰에서요?"를 다시 묻지 않게.
const feedbackEmail = 'pyodev999@gmail.com';

Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet();

  Future<void> _writeMail(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final device = Platform.isAndroid ? 'Android ${Platform.operatingSystemVersion}' : Platform.operatingSystem;
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: _encode({
        'subject': '[툭 의견]',
        'body': '\n\n\n---\n앱 버전: ${info.version} (${info.buildNumber})\n기기: $device',
      }),
    );
    final opened = await launchUrl(uri);
    if (!context.mounted) return;
    if (opened) {
      Navigator.of(context).pop();
    } else {
      await _copy(context);
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: feedbackEmail));
    if (context.mounted) showTukToast(context, '메일 주소를 복사했어요');
  }

  /// mailto 는 queryParameters 를 쓰면 공백이 + 로 바뀌어 메일 앱에 그대로 보인다 → 직접 인코딩.
  static String _encode(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  @override
  Widget build(BuildContext context) {
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
          Text('의견 보내기', style: AppText.title20),
          const SizedBox(height: AppSpace.x8),
          Text('불편한 점, 이상하게 동작한 것, 있었으면 하는 것 무엇이든 좋아요. 직접 읽고 답장할게요.',
              style: AppText.body),
          const SizedBox(height: AppSpace.x16),
          GestureDetector(
            onTap: () => _copy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(feedbackEmail, style: AppText.label15)),
                  Text('복사', style: AppText.caption13),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x24),
          PillButton.primary('메일 쓰기', onPressed: () => _writeMail(context)),
        ],
      ),
    );
  }
}
