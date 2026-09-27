/// GET /api/friendships 항목 — 내 친구.
/// { userId, nickname, profileImage }
class Friend {
  const Friend({
    required this.userId,
    required this.nickname,
    this.profileImage,
  });

  final int userId;
  final String nickname;
  final String? profileImage;

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['userId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
      );
}

/// GET /api/friendships/requests 항목 — 받은 친구 신청.
/// { friendshipId, requesterId, nickname, profileImage }
class FriendRequest {
  const FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    required this.nickname,
    this.profileImage,
  });

  final int friendshipId;
  final int requesterId;
  final String nickname;
  final String? profileImage;

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        friendshipId: json['friendshipId'] as int,
        requesterId: json['requesterId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
      );
}

/// GET /api/friendships/requests/sent 항목 — 내가 보낸 신청(아직 수락 전).
///
/// 코드를 넣고 나면 토스트 하나가 전부라 앱을 닫으면 흔적이 없었다.
/// "내가 신청했었나?" 를 확인할 자리로 둔다.
class SentFriendRequest {
  const SentFriendRequest({
    required this.friendshipId,
    required this.addresseeId,
    required this.nickname,
    this.profileImage,
  });

  final int friendshipId;
  final int addresseeId;
  final String nickname;
  final String? profileImage;

  factory SentFriendRequest.fromJson(Map<String, dynamic> json) => SentFriendRequest(
        friendshipId: json['friendshipId'] as int,
        addresseeId: json['addresseeId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
      );
}

/// POST /api/friendships 응답 — { friendshipId, status }
class FriendshipResult {
  const FriendshipResult({required this.friendshipId, required this.status});

  final int friendshipId;

  /// PENDING | ACCEPTED
  final String status;

  bool get accepted => status == 'ACCEPTED';

  factory FriendshipResult.fromJson(Map<String, dynamic> json) =>
      FriendshipResult(
        friendshipId: json['friendshipId'] as int,
        status: json['status'] as String,
      );
}

/// 초대코드 방식 (백엔드 추가 예정).
/// GET /api/friendships/invite-code → { code }
/// POST /api/friendships/redeem { code } → FriendshipResult
class InviteCode {
  const InviteCode({required this.code});

  final String code;

  factory InviteCode.fromJson(Map<String, dynamic> json) =>
      InviteCode(code: json['code'] as String);
}
