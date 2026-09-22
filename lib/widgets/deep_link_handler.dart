import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/deep_link.dart';
import '../services/deep_link_service.dart';
import '../views/friend_add_sheet.dart';
import '../views/room_screen.dart';

/// 공유 카드 링크를 실제 화면으로 옮긴다. 로그인 후 홈 화면을 감싼다.
///
/// 홈에 두는 이유: 앱이 카드로 켜지면 스플래시 → 홈으로 화면이 교체되는데, 그 전에 모임방을 띄우면
/// 교체에 같이 쓸려 사라진다. 홈이 자리 잡은 뒤, 그 위에 올려야 뒤로 가기도 홈으로 자연스럽다.
/// 로그인 전에 들어온 링크는 [DeepLinkService.pending] 에 남아 있다가 로그인해 홈이 뜨면 처리된다.
class DeepLinkHandler extends StatefulWidget {
  const DeepLinkHandler({super.key, required this.child});
  final Widget child;

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  late final DeepLinkService _links;

  @override
  void initState() {
    super.initState();
    _links = context.read<DeepLinkService>();
    _links.pending.addListener(_schedule);
    _schedule();
  }

  @override
  void dispose() {
    _links.pending.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_links.pending.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  void _handle() {
    if (!mounted) return;
    final link = _links.take();
    switch (link) {
      case RoomLink(:final flashId):
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(flashId: flashId)));
      case InviteLink(:final code):
        showFriendAddSheet(context, initialCode: code);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
