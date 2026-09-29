import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/presence.dart';
import '../models/realtime_event.dart';
import '../repositories/friend_repository.dart';
import '../repositories/presence_repository.dart';
import '../services/api_client.dart';
import '../services/stomp_service.dart';

/// 화면용 한가한 친구. remainingSeconds 대신 절대 만료시각을 들고
/// 로컬에서 카운트다운한다(서버 재폴링 의존 X).
class AvailableFriend {
  AvailableFriend({
    required this.userId,
    required this.nickname,
    this.profileImage,
    required this.activity,
    required this.expiresAt,
  });

  final int userId;
  final String nickname;
  final String? profileImage;
  final Activity activity;
  final DateTime expiresAt;
}

/// 프레즌스 상태(내 콜 + 지금 한가한 친구) + 실시간.
/// STOMP 연결 lifecycle 을 소유한다(로그인 상태에 따라 start/stop).
class PresenceViewModel extends ChangeNotifier {
  PresenceViewModel({
    required PresenceRepository presence,
    required FriendRepository friend,
    required StompService stomp,
    required AccessTokenProvider accessToken,
  })  : _presence = presence,
        _friend = friend,
        _stomp = stomp,
        _accessToken = accessToken;

  final PresenceRepository _presence;
  final FriendRepository _friend;
  final StompService _stomp;
  final AccessTokenProvider _accessToken;

  StreamSubscription<PresenceEvent>? _sub;
  Timer? _ticker;
  Timer? _highlightTimer;
  bool _started = false;

  // 내 콜
  bool _myOn = false;
  Activity? _myActivity;
  DateTime? _myExpiresAt;
  bool _highlightCall = false;

  bool get myOn => _myOn;
  Activity? get myActivity => _myActivity;
  DateTime? get myExpiresAt => _myExpiresAt;
  bool get highlightCall => _highlightCall;

  // 한가한 친구
  List<AvailableFriend> _friends = [];
  List<AvailableFriend> get friends => List.unmodifiable(_friends);

  int _friendCount = 0;
  int get friendCount => _friendCount;
  bool get hasFriends => _friendCount > 0;

  bool _loading = false;
  bool get loading => _loading;

  bool _initialized = false;
  bool get initialized => _initialized;

  String? _error;
  String? get error => _error;

  // ── lifecycle ────────────────────────────────────────────

  /// 로그인 상태일 때 호출. STOMP 연결 + 구독 + 데이터 로드.
  void start() {
    // 토큰 문자열이 아니라 '받아오는 방법'을 넘긴다 — 재연결마다 유효한 토큰을 새로 받게
    _stomp.connect(_accessToken);
    _sub ??= _stomp.presenceEvents.listen(_onEvent);
    _ticker ??= Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _started = true;
    load();
  }

  /// 앱이 백그라운드로 갔을 때. 실시간 연결만 끊는다(상태는 유지).
  ///
  /// 안 끊으면 서버가 계속 "접속 중"으로 보고 푸시 대신 WebSocket 으로 보내는데,
  /// 화면에 없는 앱은 그걸 보여줄 수 없다 — 새 툭·장소 변경 알림이 **아무 데도 안 뜬다**.
  /// 끊으면 서버가 미접속으로 보고 FCM 으로 보낸다.
  void pauseRealtime() {
    if (!_started) return;
    _stomp.disconnect();
  }

  /// 앱이 다시 앞으로 왔을 때. 다시 연결하고, 떨어져 있던 사이의 변화를 불러온다.
  /// 로그인 상태가 아니었으면 아무것도 안 하고 false.
  bool resumeRealtime() {
    if (!_started) return false;
    _stomp.connect(_accessToken);
    load();
    return true;
  }

  /// 로그아웃 시. 연결 해제 + 상태 초기화.
  void stop() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    _highlightTimer?.cancel();
    _stomp.disconnect();
    _started = false;
    _myOn = false;
    _myActivity = null;
    _myExpiresAt = null;
    _friends = [];
    _friendCount = 0;
    _error = null;
    _initialized = false;
    notifyListeners();
  }

  // ── 데이터 ───────────────────────────────────────────────

  Future<void> load() async {
    if (!_started) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _presence.me(),
        _presence.availableFriends(),
        _friend.friends(),
      ]);
      _applyMe(results[0] as MyPresence);
      _friends = _sorted(
        (results[1] as List<FriendPresence>).map(_toItem).toList(),
      );
      _friendCount = (results[2] as List).length;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '불러오지 못했어요.';
    } finally {
      _loading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  void _applyMe(MyPresence me) {
    _myOn = me.available;
    _myActivity = me.activity;
    _myExpiresAt = (me.available && me.remainingSeconds != null)
        ? DateTime.now().add(Duration(seconds: me.remainingSeconds!))
        : null;
  }

  AvailableFriend _toItem(FriendPresence f) => AvailableFriend(
        userId: f.userId,
        nickname: f.nickname,
        profileImage: f.profileImage,
        activity: f.activity,
        expiresAt: DateTime.now().add(Duration(seconds: f.remainingSeconds)),
      );

  List<AvailableFriend> _sorted(List<AvailableFriend> list) {
    list.sort((a, b) {
      final c = b.expiresAt.compareTo(a.expiresAt); // 여유 많은 친구가 위
      return c != 0 ? c : a.nickname.compareTo(b.nickname);
    });
    return list;
  }

  // ── 콜 on/off ────────────────────────────────────────────

  /// 콜 켜기(시트). 성공 시 null, 실패 시 메시지.
  Future<String?> turnOn(Activity activity, int durationMinutes) async {
    try {
      final me = await _presence.turnOn(
        activity: activity.wire,
        durationMinutes: durationMinutes,
      );
      _applyMe(me);
      _flashHighlight();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return '잠시 후 다시 시도해 주세요.';
    }
  }

  /// 콜 끄기 — 낙관적 업데이트, 실패 시 원복.
  Future<String?> turnOff() async {
    final prevOn = _myOn;
    final prevActivity = _myActivity;
    final prevExpires = _myExpiresAt;
    _myOn = false;
    _myActivity = null;
    _myExpiresAt = null;
    notifyListeners();
    try {
      await _presence.turnOff();
      return null;
    } on ApiException catch (e) {
      _myOn = prevOn;
      _myActivity = prevActivity;
      _myExpiresAt = prevExpires;
      notifyListeners();
      return e.message;
    } catch (_) {
      _myOn = prevOn;
      _myActivity = prevActivity;
      _myExpiresAt = prevExpires;
      notifyListeners();
      return '잠시 후 다시 시도해 주세요.';
    }
  }

  void _flashHighlight() {
    _highlightCall = true;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 3), () {
      _highlightCall = false;
      notifyListeners();
    });
  }

  // ── 실시간 ───────────────────────────────────────────────

  void _onEvent(PresenceEvent e) {
    if (e.isAvailable) {
      final item = AvailableFriend(
        userId: e.userId,
        nickname: e.nickname ?? '친구',
        profileImage: e.profileImage,
        activity: e.activity ?? Activity.anything,
        expiresAt:
            DateTime.now().add(Duration(seconds: e.remainingSeconds ?? 0)),
      );
      final next = _friends.where((f) => f.userId != e.userId).toList()
        ..add(item);
      _friends = _sorted(next);
    } else {
      _friends = _friends.where((f) => f.userId != e.userId).toList();
    }
    notifyListeners();
  }

  /// 1분 tick — 만료된 카드 제거 + 내 콜 만료 반영 + 문구 갱신.
  void _tick() {
    final now = DateTime.now();
    _friends = _friends.where((f) => f.expiresAt.isAfter(now)).toList();
    if (_myOn && _myExpiresAt != null && !_myExpiresAt!.isAfter(now)) {
      _myOn = false;
      _myActivity = null;
      _myExpiresAt = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }
}
