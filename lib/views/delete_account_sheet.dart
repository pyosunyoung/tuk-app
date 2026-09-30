import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import '../widgets/confirm_sheet.dart';

/// 탈퇴 확인. 탈퇴에 성공하면 true.
/// 무엇이 지워지는지 먼저 말한다 — 특히 내가 던진 툭이 친구 화면에서도 사라진다는 것.
Future<bool> showDeleteAccountSheet(BuildContext context) {
  final auth = context.read<AuthViewModel>();
  return showConfirmSheet(
    context,
    title: '툭을 탈퇴할까요?',
    lines: const [
      '내가 던진 툭과 모임방이 지워져요. 합류한 친구 화면에서도 사라져요.',
      '친구 목록에서 조용히 빠져요. 친구에게 따로 알리지 않아요.',
      '되돌릴 수 없어요. 다시 가입하면 새 계정으로 시작해요.',
    ],
    confirmLabel: '탈퇴하기',
    cancelLabel: '계속 쓸게요',
    onConfirm: auth.deleteAccount,
  );
}
