import 'activity.dart';

/// MeetupRoom — 합류/모임방 응답.
class MeetupRoom {
  const MeetupRoom({
    required this.roomId,
    required this.flashId,
    required this.activity,
    this.placeName,
    this.placeLat,
    this.placeLng,
    this.placeKakaoId,
    this.placeAddress,
    this.placeSetById,
    this.placeSetByNickname,
    this.placeChanged = false,
    this.meetAt,
    this.meetAtSetById,
    this.meetAtSetByNickname,
    this.meetAtChanged = false,
    required this.status,
    this.expiresAt,
    required this.members,
  });

  final int roomId;
  final int flashId;
  final Activity activity;
  final String? placeName;
  final double? placeLat;
  final double? placeLng;

  /// 검색으로 고른 장소일 때만 값이 있다(직접 입력이면 null).
  final String? placeKakaoId;
  final String? placeAddress;

  /// 장소를 정한 멤버. 아무도 안 정했으면 null.
  /// 장소는 멤버 누구나 다시 정할 수 있고, 마지막으로 바꾼 사람으로 덮인다.
  final int? placeSetById;
  final String? placeSetByNickname;

  /// 마지막 동작이 "바꿈"이었나(처음 정함이면 false). "OO님이 정했어요 / 바꿨어요"에 쓴다.
  final bool placeChanged;

  /// 만나기로 한 시각. 아직 안 정했으면 null.
  /// [expiresAt](모집 마감)과 다른 시각이다 — 약속을 정해도 만료는 늘어나지 않는다.
  final DateTime? meetAt;

  /// 약속 시간을 정한 멤버. 장소와 같이 아무나 다시 정할 수 있다.
  final int? meetAtSetById;
  final String? meetAtSetByNickname;
  final bool meetAtChanged;

  /// OPEN | CLOSED
  final String status;

  /// 번개 만료 시각. 공유 링크로 방에 바로 들어오는 경로가 있어 방 응답에 함께 온다.
  final DateTime? expiresAt;

  final List<RoomMember> members;

  bool get hasPlace => placeName != null;
  bool get hasMeetAt => meetAt != null;

  factory MeetupRoom.fromJson(Map<String, dynamic> json) => MeetupRoom(
        roomId: json['roomId'] as int,
        flashId: json['flashId'] as int,
        activity: Activity.fromWire(json['activity'] as String?),
        placeName: json['placeName'] as String?,
        placeLat: (json['placeLat'] as num?)?.toDouble(),
        placeLng: (json['placeLng'] as num?)?.toDouble(),
        placeKakaoId: json['placeKakaoId'] as String?,
        placeAddress: json['placeAddress'] as String?,
        placeSetById: json['placeSetById'] as int?,
        placeSetByNickname: json['placeSetByNickname'] as String?,
        placeChanged: json['placeChanged'] as bool? ?? false,
        meetAt: json['meetAt'] == null
            ? null
            : DateTime.tryParse(json['meetAt'] as String),
        meetAtSetById: json['meetAtSetById'] as int?,
        meetAtSetByNickname: json['meetAtSetByNickname'] as String?,
        meetAtChanged: json['meetAtChanged'] as bool? ?? false,
        status: json['status'] as String? ?? 'OPEN',
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => RoomMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// members 항목 — { userId, nickname, profileImage, sender }
class RoomMember {
  const RoomMember({
    required this.userId,
    required this.nickname,
    this.profileImage,
    required this.sender,
  });

  final int userId;
  final String nickname;
  final String? profileImage;

  /// 보낸 사람이면 true
  final bool sender;

  factory RoomMember.fromJson(Map<String, dynamic> json) => RoomMember(
        userId: json['userId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
        sender: json['sender'] as bool? ?? false,
      );
}
