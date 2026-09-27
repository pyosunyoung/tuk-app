import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import '../repositories/friend_repository.dart';
import '../services/api_client.dart';

/// 코드 입력(redeem) 결과 분류 — 시트 유지 여부와 토스트 문구를 가른다.
enum RedeemOutcome { accepted, pending, notFound, ownCode, alreadyFriend, failed }

class RedeemResult {
  const RedeemResult(this.outcome, this.message);
  final RedeemOutcome outcome;
  final String message;

  /// 성공(accepted/pending) 이면 시트를 닫는다.
  bool get closeSheet =>
      outcome == RedeemOutcome.accepted || outcome == RedeemOutcome.pending;
}

/// 친구 상태 — 받은 신청 + 내 절친 + 내 초대코드.
class FriendViewModel extends ChangeNotifier {
  FriendViewModel(this._repo);

  final FriendRepository _repo;

  List<Friend> _friends = [];
  List<Friend> get friends => List.unmodifiable(_friends);

  List<FriendRequest> _requests = [];
  List<FriendRequest> get requests => List.unmodifiable(_requests);

  /// 내가 보낸 신청(아직 수락 전). 친구 목록 아래에 조용히 둔다.
  List<SentFriendRequest> _sentRequests = [];
  List<SentFriendRequest> get sentRequests => List.unmodifiable(_sentRequests);

  int get requestCount => _requests.length;

  String? _inviteCode;
  String? get inviteCode => _inviteCode;

  bool _loading = false;
  bool get loading => _loading;

  bool _initialized = false;
  bool get initialized => _initialized;

  String? _error;
  String? get error => _error;

  // ── lifecycle ────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.friends(),
        _repo.receivedRequests(),
        _repo.sentRequests(),
      ]);
      _friends = _sorted(results[0] as List<Friend>);
      _requests = results[1] as List<FriendRequest>;
      _sentRequests = results[2] as List<SentFriendRequest>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '잠시 후 다시 시도해 주세요';
    } finally {
      _loading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  void reset() {
    _friends = [];
    _requests = [];
    _sentRequests = [];
    _inviteCode = null;
    _initialized = false;
    _error = null;
    notifyListeners();
  }

  List<Friend> _sorted(List<Friend> list) {
    list.sort((a, b) => a.nickname.compareTo(b.nickname));
    return list;
  }

  // ── 초대코드 ─────────────────────────────────────────────

  /// 내 코드 조회(없으면 생성). 실패 시 null 유지.
  Future<String?> ensureInviteCode() async {
    if (_inviteCode != null) return _inviteCode;
    try {
      final code = await _repo.myInviteCode();
      _inviteCode = code.code;
      notifyListeners();
      return _inviteCode;
    } catch (_) {
      return null;
    }
  }

  // ── 수락 ─────────────────────────────────────────────────

  /// 받은 신청 수락 — 낙관적: 신청 제거 + 절친 삽입. 실패 시 원복.
  /// 성공 시 상대 닉네임 반환(토스트용), 실패 시 null + [error] 세팅.
  Future<String?> accept(int friendshipId) async {
    final idx = _requests.indexWhere((r) => r.friendshipId == friendshipId);
    if (idx < 0) return null;
    final req = _requests[idx];

    _requests = List.of(_requests)..removeAt(idx);
    _friends = _sorted(List.of(_friends)
      ..add(Friend(
          userId: req.requesterId,
          nickname: req.nickname,
          profileImage: req.profileImage)));
    notifyListeners();

    try {
      await _repo.accept(friendshipId);
      return req.nickname;
    } catch (e) {
      // 원복
      _friends = _friends.where((f) => f.userId != req.requesterId).toList();
      _requests = _sorted2(List.of(_requests)..add(req));
      _error = e is ApiException ? e.message : '잠시 후 다시 시도해 주세요';
      notifyListeners();
      return null;
    }
  }

  List<FriendRequest> _sorted2(List<FriendRequest> list) {
    // 신청은 특별한 정렬 규칙이 없어 원래 순서 유지(닉네임 보조 정렬)
    list.sort((a, b) => a.nickname.compareTo(b.nickname));
    return list;
  }

  // ── 코드 입력(redeem) ────────────────────────────────────

  Future<RedeemResult> redeem(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    try {
      final result = await _repo.redeem(code);
      // 성공 → 친구 목록 갱신(수락된 경우 바로 반영)
      await load();
      if (result.accepted) {
        return const RedeemResult(RedeemOutcome.accepted, '친구가 됐어요');
      }
      return const RedeemResult(
          RedeemOutcome.pending, '신청을 보냈어요 · 수락하면 알려줄게요');
    } on ApiException catch (e) {
      return _classify(e);
    } catch (_) {
      return const RedeemResult(RedeemOutcome.failed, '잠시 후 다시 시도해 주세요');
    }
  }

  RedeemResult _classify(ApiException e) {
    final msg = e.message;
    if (e.statusCode == 404) {
      return const RedeemResult(
          RedeemOutcome.notFound, '코드를 못 찾았어요. 다시 확인해 주세요');
    }
    if (msg.contains('본인')) {
      return const RedeemResult(
          RedeemOutcome.ownCode, '내 코드예요. 친구에게 알려주세요');
    }
    if (msg.contains('이미 친구')) {
      return const RedeemResult(RedeemOutcome.alreadyFriend, '이미 친구예요');
    }
    return RedeemResult(RedeemOutcome.failed, msg);
  }
}
