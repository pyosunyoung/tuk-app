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
    required this.status,
    required this.members,
  });

  final int roomId;
  final int flashId;
  final Activity activity;
  final String? placeName;
  final double? placeLat;
  final double? placeLng;

  /// OPEN | CLOSED
  final String status;
  final List<RoomMember> members;

  bool get hasPlace => placeName != null;

  factory MeetupRoom.fromJson(Map<String, dynamic> json) => MeetupRoom(
        roomId: json['roomId'] as int,
        flashId: json['flashId'] as int,
        activity: Activity.fromWire(json['activity'] as String?),
        placeName: json['placeName'] as String?,
        placeLat: (json['placeLat'] as num?)?.toDouble(),
        placeLng: (json['placeLng'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'OPEN',
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
