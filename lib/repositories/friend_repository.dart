import '../core/config.dart';
import '../models/friend.dart';
import '../services/api_client.dart';

class FriendRepository {
  FriendRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/friendships';

  Future<List<Friend>> friends() async {
    final data = await _api.get(_base);
    return (data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<FriendRequest>> receivedRequests() async {
    final data = await _api.get('$_base/requests');
    return (data as List)
        .map((e) => FriendRequest.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// 내가 보낸 신청(아직 수락 전).
  Future<List<SentFriendRequest>> sentRequests() async {
    final data = await _api.get('$_base/requests/sent');
    return (data as List)
        .map((e) => SentFriendRequest.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> accept(int friendshipId) async {
    await _api.post('$_base/$friendshipId/accept');
  }

  /// 상대 userId 를 직접 알 때 (내부/디버그용 경로).
  /// 친구 끊기. 양쪽 목록에서 사라지고 상대에게 알림은 없다.
  Future<void> unfriend(int friendUserId) => _api.delete('$_base/friends/$friendUserId');

  /// 내가 보낸 신청 취소(받은 신청을 지우는 API 는 없다 — 거절이 드러나므로).
  Future<void> cancelRequest(int friendshipId) => _api.delete('$_base/requests/$friendshipId');

  Future<FriendshipResult> requestByUserId(int addresseeId) async {
    final data = await _api.post(_base, body: {'addresseeId': addresseeId});
    return FriendshipResult.fromJson((data as Map).cast<String, dynamic>());
  }

  // ---- 초대코드 방식 (백엔드 추가) ------------------------------------

  /// 내 초대코드 조회(없으면 생성).
  Future<InviteCode> myInviteCode() async {
    final data = await _api.get('$_base/invite-code');
    return InviteCode.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 초대코드로 친구 맺기.
  Future<FriendshipResult> redeem(String code) async {
    final data = await _api.post('$_base/redeem', body: {'code': code});
    return FriendshipResult.fromJson((data as Map).cast<String, dynamic>());
  }
}
