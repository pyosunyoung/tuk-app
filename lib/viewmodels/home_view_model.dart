import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/presence.dart';
import '../models/realtime_event.dart';
import '../services/api_client.dart';
import '../services/stomp_service.dart';
import '../repositories/presence_repository.dart';

/// 홈 화면 — 내 콜 상태 + 지금 한가한 친구. presence 실시간 반영.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required PresenceRepository presence,
    required StompService stomp,
  })  : _repo = presence,
        _stomp = stomp {
    _sub = _stomp.presenceEvents.listen(_onPresenceEvent);
  }

  final PresenceRepository _repo;
  final StompService _stomp;
  StreamSubscription? _sub;

  MyPresence _me = MyPresence.off();
  MyPresence get me => _me;

  List<FriendPresence> _friends = [];
  List<FriendPresence> get friends => _friends;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.me(), _repo.availableFriends()]);
      _me = results[0] as MyPresence;
      _friends = results[1] as List<FriendPresence>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '목록을 불러오지 못했어요.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> turnOn(Activity activity, int durationMinutes) async {
    try {
      _me = await _repo.turnOn(
        activity: activity.wire,
        durationMinutes: durationMinutes,
      );
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return '콜을 켜지 못했어요.';
    }
  }

  Future<String?> turnOff() async {
    try {
      await _repo.turnOff();
      _me = MyPresence.off();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return '콜을 끄지 못했어요.';
    }
  }

  /// 실시간: 친구가 콜 켜고/끄면 목록 갱신.
  void _onPresenceEvent(PresenceEvent e) {
    if (e.isAvailable) {
      final entry = FriendPresence(
        userId: e.userId,
        nickname: e.nickname ?? '친구',
        profileImage: e.profileImage,
        activity: e.activity ?? Activity.anything,
        remainingSeconds: e.remainingSeconds ?? 0,
      );
      final idx = _friends.indexWhere((f) => f.userId == e.userId);
      if (idx >= 0) {
        _friends[idx] = entry;
      } else {
        _friends = [entry, ..._friends];
      }
    } else {
      _friends = _friends.where((f) => f.userId != e.userId).toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
