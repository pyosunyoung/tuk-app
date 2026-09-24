import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/flash.dart';
import '../models/meetup_room.dart';
import '../models/place.dart';
import '../models/realtime_event.dart';
import '../repositories/flash_repository.dart';
import '../repositories/place_repository.dart';
import '../services/api_client.dart';
import '../services/stomp_service.dart';

/// 툭(Flash) 상태 — 발송·모임방·장소·합류 + 받은/내가 던진 목록 + 실시간.
class FlashViewModel extends ChangeNotifier {
  FlashViewModel({
    required FlashRepository flash,
    required PlaceRepository place,
    required StompService stomp,
  })  : _repo = flash,
        _places = place,
        _stomp = stomp {
    _sub = _stomp.flashEvents.listen(_onEvent);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  final FlashRepository _repo;
  final PlaceRepository _places;
  final StompService _stomp;
  StreamSubscription<FlashPushEvent>? _sub;
  Timer? _ticker;

  /// 방 화면 등이 직접 구독할 수 있게 flash 이벤트 노출.
  Stream<FlashPushEvent> get events => _stomp.flashEvents;

  List<ReceivedFlash> _received = [];
  List<ReceivedFlash> get received => List.unmodifiable(_received);

  List<SentFlash> _sent = [];
  List<SentFlash> get sent => List.unmodifiable(_sent);

  bool _loaded = false;
  bool get loaded => _loaded;

  /// 미합류(PENDING) 받은 번개 수 — 배너 배지.
  int get pendingReceivedCount => _received.where((f) => !f.joined).length;

  // ── lifecycle ────────────────────────────────────────────

  Future<void> load() async {
    try {
      final results = await Future.wait([_repo.received(), _repo.sent()]);
      _received = _sortReceived(results[0] as List<ReceivedFlash>);
      _sent = results[1] as List<SentFlash>;
    } catch (_) {
      // 배너/목록은 조용히 실패 — 화면 진입 시 재시도
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void reset() {
    _received = [];
    _sent = [];
    _loaded = false;
    notifyListeners();
  }

  Future<void> reloadReceived() async {
    try {
      _received = _sortReceived(await _repo.received());
      notifyListeners();
    } catch (_) {}
  }

  Future<void> reloadSent() async {
    try {
      _sent = await _repo.sent();
      notifyListeners();
    } catch (_) {}
  }

  bool _reserved(ReceivedFlash f) =>
      f.scheduledAt != null && f.scheduledAt!.isAfter(DateTime.now());

  int _rank(ReceivedFlash f) {
    if (f.joined) return 2;
    if (_reserved(f)) return 1; // 예약(미합류)은 합류 그룹 위
    return 0; // 미합류 지금
  }

  List<ReceivedFlash> _sortReceived(List<ReceivedFlash> list) {
    list.sort((a, b) {
      final ra = _rank(a), rb = _rank(b);
      if (ra != rb) return ra.compareTo(rb);
      if (ra == 1) {
        return (a.scheduledAt ?? a.expiresAt ?? DateTime.now())
            .compareTo(b.scheduledAt ?? b.expiresAt ?? DateTime.now());
      }
      // 지금/합류: 곧 끝나는 것이 위
      return (a.expiresAt ?? DateTime.now()).compareTo(b.expiresAt ?? DateTime.now());
    });
    return list;
  }

  // ── 발송/모임방 (checkpoint A) ────────────────────────────

  Future<FlashCreated> send({
    required Activity activity,
    String? message,
    List<int>? targetUserIds,
    required int durationMinutes,
    DateTime? scheduledAt,
  }) {
    return _repo.send(
      activity: activity.wire,
      message: message,
      targetUserIds: targetUserIds,
      durationMinutes: durationMinutes,
      scheduledAt: scheduledAt,
    );
  }

  Future<MeetupRoom> room(int flashId) => _repo.room(flashId);

  Future<MeetupRoom> join(int flashId) async {
    final room = await _repo.join(flashId);
    // 로컬: 해당 받은 번개를 JOINED 로 표시
    final idx = _received.indexWhere((f) => f.flashId == flashId);
    if (idx >= 0 && !_received[idx].joined) {
      _received[idx] = _asJoined(_received[idx]);
      _received = _sortReceived(_received);
      notifyListeners();
    }
    return room;
  }

  ReceivedFlash _asJoined(ReceivedFlash f) => ReceivedFlash(
        flashId: f.flashId,
        senderId: f.senderId,
        senderNickname: f.senderNickname,
        senderProfileImage: f.senderProfileImage,
        activity: f.activity,
        message: f.message,
        scheduledAt: f.scheduledAt,
        expiresAt: f.expiresAt,
        myStatus: 'JOINED',
      );

  Future<MeetupRoom> setPlace(int flashId, Place place) => _repo.setPlace(flashId, place);

  Future<MeetupRoom> setMeetAt(int flashId, DateTime meetAt) =>
      _repo.setMeetAt(flashId, meetAt);

  /// 모임방 장소 검색(카카오 로컬 API 를 서버가 대신 호출).
  Future<List<Place>> searchPlaces(String query) => _places.search(query);

  bool isEnded(Object e) =>
      e is ApiException && (e.statusCode == 400 || e.statusCode == 404);

  // ── 실시간 ───────────────────────────────────────────────

  void _onEvent(FlashPushEvent e) {
    if (e.isNewFlash) {
      reloadReceived(); // 새 툭 도착 → 목록/배너 갱신
    } else if (e.isMemberJoined) {
      reloadSent(); // 누가 합류 → 홈 "내가 던진 툭" 의 "N명 모였어요" 갱신
    }
  }

  /// 1분마다 남은 시간 문구를 갱신하고, 끝난 것은 목록에서 치운다.
  ///
  /// **합류 마감만 보고 지우면 안 된다.** 약속 시간이 잡힌 모임은 마감이 지나도
  /// "어디서 몇 시더라"를 다시 볼 수 있어야 해서 서버가 계속 내려준다.
  /// 여기서 마감만 보고 지우면, 서버엔 있는데 화면에서만 사라진다
  /// (실제로 약속을 잡아둔 모임이 1분 뒤 조용히 없어졌다).
  void _tick() {
    final now = DateTime.now();
    bool alive(DateTime? expiresAt, DateTime? meetAt) {
      final until = _later(expiresAt, meetAt);
      return until == null || until.isAfter(now);
    }

    final r = _received.where((f) => alive(f.expiresAt, f.meetAt)).toList();
    final s = _sent.where((f) => alive(f.expiresAt, f.meetAt)).toList();
    if (r.length != _received.length || s.length != _sent.length) {
      _received = r;
      _sent = s;
    }
    notifyListeners();
  }

  static DateTime? _later(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
