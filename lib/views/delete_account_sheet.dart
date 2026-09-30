import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../services/api_client.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/primitives.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';

/// 탈퇴 확인 시트. 탈퇴에 성공하면 true.
///
/// 되돌릴 수 없는 행동이라 한 번 더 묻는다("합류는 버튼에서만"과 같은 기준).
/// 무엇이 지워지는지 먼저 말한다 — 특히 내가 띄운 툭이 친구 화면에서도 사라진다는 것.
/// 빨강은 쓰지 않는다(툭은 겁주지 않는 앱). 대신 문구로 분명히 말한다.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    isScrollControlled: true,
    builder: (_) => const _DeleteAccountSheet(),
  );
  return done ?? false;
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  bool _busy = false;

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthViewModel>().deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTukToast(context, e.message);
    }
  }

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
          Text('툭을 탈퇴할까요?', style: AppText.title20),
          const SizedBox(height: AppSpace.x16),
          const _Line('내가 띄운 툭과 모임방이 지워져요. 합류한 친구 화면에서도 사라져요.'),
          const _Line('친구 목록에서 조용히 빠져요. 친구에게 따로 알리지 않아요.'),
          const _Line('되돌릴 수 없어요. 다시 가입하면 새 계정으로 시작해요.'),
          const SizedBox(height: AppSpace.x24),
          PillButton.primary('탈퇴하기', onPressed: _busy ? null : _delete, loading: _busy),
          const SizedBox(height: AppSpace.x8),
          PillButton.secondary('계속 쓸게요',
              onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: AppSpace.x8),
            child: Container(width: 4, height: 4,
                decoration: const BoxDecoration(color: AppColors.textSub, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
