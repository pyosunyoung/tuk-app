/// 내 정보 — `GET /api/users/me`.
///
/// 앱이 "이게 나"라고 판단하는 기준. 모임방 참여자 중 '나' 표시,
/// 홈 프로필 아바타에 쓴다.
class Me {
  const Me({
    required this.userId,
    required this.nickname,
    this.profileImage,
  });

  final int userId;
  final String nickname;
  final String? profileImage;

  factory Me.fromJson(Map<String, dynamic> json) => Me(
        userId: json['userId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
      );
}
