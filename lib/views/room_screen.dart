import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/open_routes.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/meetup_room.dart';
import '../models/realtime_event.dart';
import '../services/api_client.dart';
import '../services/kakao_share_service.dart';
import '../services/map_launcher.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/flash_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'flash_compose_screen.dart';
import 'map_app_sheet.dart';
import 'meet_time_sheet.dart';
import 'place_sheet.dart';

/// 모임방 (11c) — 합류한 사람이 모여 언제·어디서 만날지 맞춘다.
/// 만료 시각은 방 응답에 들어 있다. 생성자의 [expiresAt] 은 방을 불러오기 전에도 남은 시간을
/// 보여주기 위한 선행(발송/받은번개) 값일 뿐이라, 방이 오면 방 쪽 값이 이긴다.
/// 공유 링크로 바로 들어오면 선행 값이 없으므로 이 구분이 중요하다.
class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    required this.flashId,
    this.expiresAt,
    this.initialToast,
  });

  final int flashId;
  final DateTime? expiresAt;
  final String? initialToast;

  /// 이 모임방이 지금 떠 있나. 장소·시간 변경 토스트를 방 안에서 띄우면
  /// 앱 루트는 같은 토스트를 또 띄우지 않고, 알림을 탭하면 새로 쌓지 않고 이 방으로 돌아간다(main.dart).
  static String routeKey(int flashId) => 'room:$flashId';
  static bool isOpen(int flashId) => OpenRoutes.isOpen(routeKey(flashId));

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

/// 다른 멤버가 장소·시간을 정하거나 바꿨을 때의 토스트 문구.
/// 처음 정함과 바꿈을 구분한다 — 바뀐 걸 모르면 옛 장소·시간으로 가는 사고가 난다.
String planUpdateText(FlashPushEvent e) {
  final who = '${e.nickname ?? '친구'}님이';
  if (e.isPlaceUpdated) {
    final verb = e.placeBefore == null ? '정했어요' : '바꿨어요';
    return '$who 장소를 $verb · ${e.placeAfter ?? ''}';
  }
  final verb = e.meetAtBefore == null ? '정했어요' : '바꿨어요';
  final when = e.meetAtAfter == null ? '' : ' · ${meetTimeLabel(e.meetAtAfter!)}';
  return '$who 시간을 $verb$when';
}

class _RoomScreenState extends State<RoomScreen>
    with WidgetsBindingObserver, OpenRouteTracking<RoomScreen> {
  @override
  String get openRouteKey => RoomScreen.routeKey(widget.flashId);

  MeetupRoom? _room;
  bool _loading = true;
  String? _error;
  late final FlashViewModel _vm;
  StreamSubscription? _evSub;

  @override
  void initState() {
    super.initState();
    _vm = context.read<FlashViewModel>();
    WidgetsBinding.instance.addObserver(this);
    // 실시간: 이 방에 누가 합류하면 조용히 참여자 갱신(토스트 없음).
    // 장소·시간이 바뀌면 갱신 + 토스트 — 보고 있던 값이 말없이 바뀌면 오히려 헷갈린다.
    _evSub = _vm.events.listen((e) {
      if (e.flashId != widget.flashId || !mounted) return;
      if (e.isMemberJoined) {
        _load();
      } else if (e.isPlanUpdated) {
        _load();
        showTukToast(context, planUpdateText(e));
      }
    });
    _load();
    if (widget.initialToast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showTukToast(context, widget.initialToast!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _evSub?.cancel();
    super.dispose();
  }

  /// 백그라운드에선 실시간 연결을 끊으므로(main.dart), 돌아오면 그 사이 바뀐 장소·시간·멤버를 다시 불러온다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  /// 방 응답의 만료 시각이 진짜. 아직 안 불러왔으면 넘겨받은 값으로 버틴다.
  DateTime? get _expiresAt => _room?.expiresAt ?? widget.expiresAt;

  /// 합류 마감 — 새 사람이 못 들어온다. **모임이 끝난 건 아니다.**
  bool get _joinClosed =>
      (_room?.status == 'CLOSED') ||
      (_expiresAt != null && flashEnded(_expiresAt!));

  /// 모임 종료 — 약속 시간까지 지났거나, 약속 없이 합류가 끝났다. 이제 읽기 전용 기록이다.
  ///
  /// 합류 마감과 나누는 이유: 7시 약속인데 6시에 합류가 마감되는 일이 흔하고,
  /// 그 사이에 "비 와서 실내로 바꾸자" 처럼 장소·시간을 고칠 일이 생긴다.
  /// 둘을 한 덩어리로 보면 아직 만나지도 않은 모임이 박제된다.
  /// (서버는 원래 멤버면 마감 뒤에도 수정을 허용한다 — 앱만 잠그고 있었다)
  bool get _over {
    final meetAt = _room?.meetAt;
    if (meetAt != null) return flashEnded(meetAt);
    return _joinClosed;
  }

  Future<void> _load() async {
    try {
      final r = await _vm.room(widget.flashId);
      if (mounted) setState(() { _room = r; _loading = false; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    }
  }

  Future<void> _editMeetTime() async {
    final when = await showMeetTimeSheet(context, current: _room?.meetAt);
    if (when == null || !mounted) return;
    final had = _room?.hasMeetAt ?? false;
    try {
      final updated = await _vm.setMeetAt(widget.flashId, when);
      if (!mounted) return;
      setState(() => _room = updated);
      showTukToast(context, had ? '시간을 바꿨어요' : '시간을 정했어요');
    } on ApiException catch (e) {
      if (mounted) showTukToast(context, e.message);
    }
  }

  Future<void> _editPlace() async {
    final place = await showPlaceSheet(
      context,
      current: _room?.placeName,
      search: _vm.searchPlaces,
    );
    if (place == null || place.name.isEmpty || !mounted) return;
    final had = _room?.hasPlace ?? false;
    try {
      final updated = await _vm.setPlace(widget.flashId, place);
      if (!mounted) return;
      setState(() => _room = updated);
      showTukToast(context, had ? '장소를 바꿨어요' : '장소를 정했어요');
    } on ApiException catch (e) {
      if (mounted) showTukToast(context, e.message);
    }
  }

  /// 정해진 장소를 외부 지도 앱으로 연다 (P1). 길찾기는 지도 앱에 맡긴다.
  Future<void> _openMap(MeetupRoom room) async {
    const launcher = MapLauncher();
    final lastUsed = await launcher.lastUsed();
    if (!mounted) return;
    final app = await showMapAppSheet(
      context,
      placeName: room.placeName!,
      lastUsed: lastUsed,
    );
    if (app == null || !mounted) return;
    final opened = await launcher.open(
      app,
      placeName: room.placeName!,
      lat: room.placeLat,
      lng: room.placeLng,
      kakaoPlaceId: room.placeKakaoId,
    );
    if (!opened && mounted) showTukToast(context, '지도를 열지 못했어요');
  }

  /// 모임 정보를 카카오톡 공유 카드로 — 받은 사람이 누르면 툭의 이 모임방이 열린다.
  Future<void> _shareToKakao(MeetupRoom room) => const KakaoShareService().shareRoom(
        flashId: widget.flashId,
        activity: room.activity,
        placeName: room.placeName,
        placeAddress: room.placeAddress,
        kakaoPlaceId: room.placeKakaoId,
        meetAt: room.meetAt,
        expiresAt: _expiresAt,
      );

  void _resend() {
    Navigator.of(context).push(flashComposeRoute(prefillActivity: _room?.activity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpace.x20, right: AppSpace.x20, top: AppSpace.x8, bottom: AppSpace.x12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(width: 36, height: 36,
                        child: Icon(Icons.arrow_back, size: 22, color: AppColors.text)),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Text('모임방', style: AppText.title20),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _room == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && _room == null) {
      return _ErrorRetry(message: _error!, onRetry: _load);
    }
    final room = _room!;
    final over = _over;          // 읽기 전용 기록
    final joinClosed = _joinClosed; // 새 사람만 못 들어옴
    final members = [...room.members]..sort((a, b) => a.sender == b.sender ? 0 : (a.sender ? -1 : 1));
    final joinedOnly = members.where((m) => !m.sender).isEmpty;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, 46),
        children: [
          _infoCard(room, joinClosed, over),
          const SizedBox(height: AppSpace.x8),
          _meetTimeCard(room, over),
          const SizedBox(height: AppSpace.x8),
          _placeCard(room, over),
          if (!over) ...[
            const SizedBox(height: AppSpace.x12),
            // 채팅은 만들지 않는다 — 대화는 카톡으로. 모임 정보를 카드로 넘긴다.
            PillButton.kakao(
              '카톡으로 이야기하기',
              leading: const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF191600)),
              onPressed: () => _shareToKakao(room),
            ),
          ],
          const SizedBox(height: AppSpace.x32),
          _sectionHeader(over ? '모였던 사람' : '모인 사람', members.length, over),
          const SizedBox(height: AppSpace.x12),
          if (over)
            _EndedMembers(members: members)
          else ...[
            ...members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x8),
                  child: _MemberCard(member: m),
                )),
            if (joinedOnly) ...[
              const SizedBox(height: AppSpace.x4),
              const _WaitingCard(),
            ],
          ],
          if (over) ...[
            const SizedBox(height: AppSpace.x24),
            Center(child: Text('다음에 또 툭 던져보세요', style: AppText.caption12)),
            const SizedBox(height: AppSpace.x12),
            PillButton.secondary('같은 내용으로 다시 던지기', onPressed: _resend),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(MeetupRoom room, bool joinClosed, bool over) {
    final ended = over;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        color: ended ? AppColors.background : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ActivityBadge(label: room.activity.label, ended: ended),
          const SizedBox(width: AppSpace.x8),
          Expanded(
            child: Text(
              over
                  ? '모임이 끝났어요 · 기록은 남아요'
                  : joinClosed
                      ? '합류는 끝났어요 · 약속은 그대로예요'
                      : (_expiresAt != null ? roomJoinDeadlineText(_expiresAt!) : ''),
              style: AppText.label14.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }

  /// 약속 시간 카드. 장소와 짝을 이룬다 — 아무나 정하고 아무나 바꾼다.
  Widget _meetTimeCard(MeetupRoom room, bool ended) {
    final set = room.hasMeetAt;
    if (ended) {
      // 끝난 방은 읽기 전용. 정해둔 시간이 있으면 그것만 남긴다(까먹었을 때 보는 자리).
      if (!set) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(AppSpace.x16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(meetTimeLabel(room.meetAt!),
            style: AppText.label15.copyWith(color: AppColors.textSub)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpace.x16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set ? meetTimeLabel(room.meetAt!) : '언제 만날까요?',
                    style: AppText.label15.copyWith(
                        color: set ? AppColors.text : AppColors.textSub,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(set ? _meetAtSetByLabel(context, room) : '아직 안 정했어요',
                    style: AppText.caption13),
              ],
            ),
          ),
          _PlaceButton(set: set, onTap: _editMeetTime),
        ],
      ),
    );
  }

  Widget _placeCard(MeetupRoom room, bool ended) {
    if (ended) {
      if (!room.hasPlace) return const SizedBox.shrink();
      return Opacity(
        opacity: 0.75,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(room.placeName!,
              style: AppText.label15.copyWith(color: AppColors.textSub)),
        ),
      );
    }
    final set = room.hasPlace;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set ? room.placeName! : '어디서 볼까요?',
                        style: AppText.label15.copyWith(
                            color: set ? AppColors.text : AppColors.textSub,
                            fontWeight: FontWeight.w600)),
                    // 검색으로 고른 장소면 주소 — 같은 이름의 다른 지점과 헷갈리지 않게
                    if (set && room.placeAddress != null) ...[
                      const SizedBox(height: 2),
                      Text(room.placeAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption13),
                    ],
                    const SizedBox(height: 3),
                    Text(set ? _placeSetByLabel(context, room) : '아직 안 정했어요',
                        style: AppText.caption13),
                  ],
                ),
              ),
              _PlaceButton(set: set, onTap: _editPlace),
            ],
          ),
          if (set) ...[
            const SizedBox(height: AppSpace.x12),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            _MapButton(onTap: () => _openMap(room)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, bool ended) {
    final color = ended ? AppColors.textSub : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.x4),
      child: Text.rich(TextSpan(
        style: AppText.title16.copyWith(color: ended ? AppColors.textSub : AppColors.text),
        children: [
          TextSpan(text: '$title '),
          TextSpan(text: '$count', style: TextStyle(color: color)),
        ],
      )),
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label, required this.ended});
  final String label;
  final bool ended;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ended ? AppColors.surface : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: ended ? Border.all(color: AppColors.border) : null,
      ),
      child: Text(label, style: AppText.label14.copyWith(
          fontWeight: FontWeight.w600,
          color: ended ? AppColors.textSub : AppColors.primaryPress)),
    );
  }
}

/// 장소 밑 한 줄 — 누가 정했는지. 서버가 정한 사람을 안 주는 옛 방이면 담백하게 넘어간다.
String _meetAtSetByLabel(BuildContext context, MeetupRoom room) {
  final me = context.read<AuthViewModel>().me?.userId;
  if (room.meetAtSetById == null) return '';
  if (room.meetAtSetById == me) return '내가 정했어요';
  final name = room.meetAtSetByNickname;
  return name == null ? '' : '$name님이 정했어요';
}

String _placeSetByLabel(BuildContext context, MeetupRoom room) {
  final setterId = room.placeSetById;
  if (setterId == null) return '장소가 정해졌어요';
  if (setterId == context.watch<AuthViewModel>().me?.userId) return '내가 정했어요';
  final name = room.placeSetByNickname;
  return name == null ? '장소가 정해졌어요' : '$name님이 정했어요';
}

class _PlaceButton extends StatelessWidget {
  const _PlaceButton({required this.set, required this.onTap});
  final bool set;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: set ? AppColors.surface : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: set ? AppColors.border : AppColors.primaryTintBorder),
        ),
        child: Text(set ? '변경' : '정하기', style: AppText.label14.copyWith(
            fontWeight: FontWeight.w600,
            color: set ? AppColors.textSub : AppColors.primaryPress)),
      ),
    );
  }
}

/// 장소 카드 하단 '지도에서 보기' 줄. 카드 안쪽 여백까지 눌리도록 세로 패딩을 크게.
class _MapButton extends StatelessWidget {
  const _MapButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.x12),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 18, color: AppColors.primaryPress),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: Text('지도에서 보기', style: AppText.label14.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.primaryPress)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final RoomMember member;
  @override
  Widget build(BuildContext context) {
    final isMe = context.watch<AuthViewModel>().me?.userId == member.userId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialAvatar(nickname: member.nickname, imageUrl: member.profileImage),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(member.nickname, overflow: TextOverflow.ellipsis,
                    style: AppText.label15.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (isMe) ...[
                const SizedBox(width: AppSpace.x4),
                Text('· 나', style: AppText.label15.copyWith(color: AppColors.textSub)),
              ],
            ]),
          ),
          if (member.sender)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.xsmall),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('던진 사람', style: AppText.caption12.copyWith(fontWeight: FontWeight.w500)),
            )
          else
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('합류', style: AppText.caption12.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w500)),
            ]),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x24, vertical: AppSpace.x32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _placeholders(),
        const SizedBox(height: AppSpace.x12),
        Text('합류하면 여기 떠요',
            style: AppText.title16.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpace.x4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text('기다리는 동안 장소를 정해두면 편해요.',
              textAlign: TextAlign.center,
              style: AppText.label14.copyWith(color: AppColors.textSub, height: 1.55)),
        ),
      ]),
    );
  }

  Widget _placeholders() {
    Widget dot() => Container(width: 38, height: 38, decoration: BoxDecoration(
        color: AppColors.background, shape: BoxShape.circle,
        border: Border.all(color: AppColors.border)));
    return SizedBox(height: 38, width: 38 * 3 - 20, child: Stack(children: [
      Positioned(left: 0, child: dot()),
      Positioned(left: 28, child: dot()),
      Positioned(left: 56, child: dot()),
    ]));
  }
}

class _EndedMembers extends StatelessWidget {
  const _EndedMembers({required this.members});
  final List<RoomMember> members;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            width: members.isEmpty
                ? 0
                : 38 + ((members.length.clamp(1, 8)) - 1) * 28.0,
            child: Stack(children: [
              for (var i = 0; i < members.length && i < 8; i++)
                Positioned(
                  left: i * 28.0,
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: AppColors.background, width: 2))),
                    child: InitialAvatar(nickname: members[i].nickname, imageUrl: members[i].profileImage),
                  ),
                ),
            ]),
          ),
          // 끝난 모임은 "누구였더라"를 다시 보는 자리다 — 얼굴만으론 알 수 없어 이름도 적는다.
          if (members.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x8),
            Text(
              members.map((m) => m.nickname).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption13,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: AppText.label14.copyWith(color: AppColors.textSub)),
        const SizedBox(height: AppSpace.x12),
        SizedBox(width: 160, child: PillButton.secondary('다시 불러오기', onPressed: onRetry)),
      ]),
    );
  }
}
