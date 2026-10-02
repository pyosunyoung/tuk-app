import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../services/kakao_share_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/presence_view_model.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import '../widgets/sheet.dart';
import '../core/keep_words.dart';

const _mono = 'monospace';

enum _Page { chooser, myCode, codeInput }

/// 친구 추가 시트 (10c). 선택 → 내 코드 / 코드 입력을 같은 시트 안에서 전환.
/// [startAtMyCode] = true 면 콜드스타트의 "내 코드 알려주기"처럼 바로 내 코드로.
/// [initialCode] 가 있으면 초대 카드로 들어온 것 — 코드가 채워진 입력 화면으로 바로.
Future<void> showFriendAddSheet(BuildContext context,
    {bool startAtMyCode = false, String? initialCode}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x472B2926),
    builder: (_) => _FriendAddSheet(
      initial: initialCode != null
          ? _Page.codeInput
          : (startAtMyCode ? _Page.myCode : _Page.chooser),
      initialCode: initialCode,
    ),
  );
}

class _FriendAddSheet extends StatefulWidget {
  const _FriendAddSheet({required this.initial, this.initialCode});
  final _Page initial;
  final String? initialCode;

  @override
  State<_FriendAddSheet> createState() => _FriendAddSheetState();
}

class _FriendAddSheetState extends State<_FriendAddSheet> {
  late _Page _page = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Color(0x142B2926), blurRadius: 24, offset: Offset(0, -4)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, sheetBottomPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
            const SizedBox(height: AppSpace.x20),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_page),
                  child: switch (_page) {
                    _Page.chooser => _Chooser(onPick: (p) => setState(() => _page = p)),
                    _Page.myCode => const _MyCode(),
                    _Page.codeInput => _CodeInput(initialCode: widget.initialCode),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 선택

class _Chooser extends StatelessWidget {
  const _Chooser({required this.onPick});
  final void Function(_Page) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(keepWords('어떻게 추가할까요?'), style: AppText.title20),
        const SizedBox(height: AppSpace.x16),
        _MenuRow(
          glyph: '코드',
          title: '내 코드 알려주기',
          desc: '친구가 입력하면 바로 연결돼요',
          onTap: () => onPick(_Page.myCode),
        ),
        const SizedBox(height: AppSpace.x8),
        _MenuRow(
          glyph: '＋',
          title: '친구 코드 입력하기',
          desc: '받은 8자 코드를 넣어보세요',
          onTap: () => onPick(_Page.codeInput),
        ),
        const SizedBox(height: AppSpace.x20),
        Center(
          child: Text(keepWords('코드로만 친구가 돼요 · 검색으로는 찾을 수 없어요'),
              style: AppText.caption12),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(
      {required this.glyph,
      required this.title,
      required this.desc,
      required this.onTap});
  final String glyph;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(keepWords(glyph),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: glyph.characters.length > 1 ? 15 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPress,
                  )),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(keepWords(title), style: AppText.title16),
                  const SizedBox(height: 3),
                  Text(keepWords(desc), style: AppText.caption13),
                ],
              ),
            ),
            Text(keepWords('›'),
                style: AppText.title20.copyWith(color: AppColors.textSub)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 내 코드

class _MyCode extends StatefulWidget {
  const _MyCode();

  @override
  State<_MyCode> createState() => _MyCodeState();
}

class _MyCodeState extends State<_MyCode> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendViewModel>().ensureInviteCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<FriendViewModel>().inviteCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(keepWords('내 초대 코드'), style: AppText.title20),
        const SizedBox(height: AppSpace.x8),
        Text(keepWords('이 코드를 친구에게 알려주세요'),
            style: AppText.label14.copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppSpace.x20),
        GestureDetector(
          onLongPress: code == null ? null : () => _copy(context, code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.primaryTintBorder),
            ),
            child: Text(keepWords(
              code ?? '········'),
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 6,
                color: code == null ? AppColors.primaryTintBorder : AppColors.primaryPress,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        Row(
          children: [
            Expanded(
              child: PillButton.secondary(
                '복사',
                onPressed: code == null ? null : () => _copy(context, code),
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: PillButton.primary(
                '공유하기',
                onPressed: code == null ? null : () => _share(code),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        Center(
          child: Text(keepWords('코드를 아는 사람만 신청할 수 있어요'),
              style: AppText.caption12),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    showTukToast(context, '코드를 복사했어요');
  }

  /// 카카오톡 초대 카드 — 받은 친구가 누르면 툭이 열리고 코드가 채워진다(카톡이 없으면 글자 공유)
  void _share(String code) {
    const KakaoShareService().shareInvite(
      code: code,
      inviterName: context.read<AuthViewModel>().me?.nickname,
    );
  }
}

// ─────────────────────────────────────────── 코드 입력

class _CodeInput extends StatefulWidget {
  const _CodeInput({this.initialCode});
  final String? initialCode;

  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  late final _controller = TextEditingController(text: widget.initialCode ?? '');
  final _focus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // 초대 카드로 들어와 코드가 이미 있으면 키보드를 띄우지 않는다 — 확인만 누르면 된다
    if (widget.initialCode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _ready => _controller.text.length == 8;

  Future<void> _submit() async {
    if (!_ready || _busy) return;
    setState(() => _busy = true);
    final fvm = context.read<FriendViewModel>();
    final result = await fvm.redeem(_controller.text);
    if (!mounted) return;
    showTukToast(context, result.message);
    if (result.closeSheet) {
      if (result.outcome == RedeemOutcome.accepted) {
        context.read<PresenceViewModel>().load(); // 홈 친구수 갱신
      }
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      if (result.outcome == RedeemOutcome.notFound) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(keepWords('친구 코드 입력'), style: AppText.title20),
        const SizedBox(height: AppSpace.x8),
        Text(keepWords('친구에게 받은 8자 코드를 넣어주세요'),
            style: AppText.label14.copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppSpace.x20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
                color: _focus.hasFocus ? AppColors.primary : AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textAlign: TextAlign.center,
            showCursor: true,
            cursorColor: AppColors.primary,
            cursorWidth: 2,
            cursorHeight: 32,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              _UpperCaseFormatter(),
            ],
            style: const TextStyle(
              fontFamily: _mono,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 5,
              color: AppColors.text,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
              hintText: '········',
              hintStyle: TextStyle(
                fontFamily: _mono,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 5,
                color: AppColors.border,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        PillButton.primary(
          '확인',
          loading: _busy,
          onPressed: _ready ? _submit : null,
        ),
        const SizedBox(height: AppSpace.x16),
        Center(
          child: Text(keepWords('상대가 수락해야 친구가 돼요'), style: AppText.caption12),
        ),
      ],
    );
  }
}

/// 입력을 대문자로.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
