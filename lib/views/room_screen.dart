import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/flash_format.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../models/meetup_room.dart';
import '../services/api_client.dart';
import '../services/map_launcher.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/flash_view_model.dart';
import '../widgets/avatar.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'flash_compose_screen.dart';
import 'map_app_sheet.dart';
import 'place_sheet.dart';

/// 모임방 (11c) — 합류한 사람이 모여 언제·어디서 만날지 맞춘다.
/// expiresAt 은 방 응답에 없어 선행(발송/받은번개) 응답에서 받아 전달한다.
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

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  MeetupRoom? _room;
  bool _loading = true;
  String? _error;
  late final FlashViewModel _vm;
  StreamSubscription? _evSub;

  @override
  void initState() {
    super.initState();
    _vm = context.read<FlashViewModel>();
    // 실시간: 이 방에 누가 합류하면 조용히 참여자 갱신(토스트 없음).
    _evSub = _vm.events.listen((e) {
      if (e.isMemberJoined && e.flashId == widget.flashId && mounted) _load();
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
    _evSub?.cancel();
    super.dispose();
  }

  bool get _ended =>
      (_room?.status == 'CLOSED') ||
      (widget.expiresAt != null && flashEnded(widget.expiresAt!));

  Future<void> _load() async {
    try {
      final r = await _vm.room(widget.flashId);
      if (mounted) setState(() { _room = r; _loading = false; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
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
    final ended = _ended;
    final members = [...room.members]..sort((a, b) => a.sender == b.sender ? 0 : (a.sender ? -1 : 1));
    final joinedOnly = members.where((m) => !m.sender).isEmpty;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, AppSpace.x20, 46),
        children: [
          _infoCard(room, ended),
          const SizedBox(height: AppSpace.x8),
          _placeCard(room, ended),
          const SizedBox(height: AppSpace.x32),
          _sectionHeader(ended ? '모였던 사람' : '모인 사람', members.length, ended),
          const SizedBox(height: AppSpace.x12),
          if (ended)
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
          if (ended) ...[
            const SizedBox(height: AppSpace.x24),
            Center(child: Text('다음에 또 툭 던져보세요', style: AppText.caption12)),
            const SizedBox(height: AppSpace.x12),
            PillButton.secondary('같은 내용으로 다시 띄우기', onPressed: _resend),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(MeetupRoom room, bool ended) {
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
              ended
                  ? '끝났어요 · 곧 사라져요'
                  : (widget.expiresAt != null ? flashExpiryText(widget.expiresAt!) : ''),
              style: AppText.label14.copyWith(color: AppColors.textSub),
            ),
          ),
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
              child: Text('띄운 사람', style: AppText.caption12.copyWith(fontWeight: FontWeight.w500)),
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
      child: SizedBox(
        height: 38,
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
