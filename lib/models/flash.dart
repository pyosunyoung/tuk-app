import 'activity.dart';

/// GET /api/flashes/received 항목 — 받은 활성 번개.
/// { flashId, senderId, senderNickname, senderProfileImage, activity,
///   message, scheduledAt, expiresAt, myStatus }
class ReceivedFlash {
  const ReceivedFlash({
    required this.flashId,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileImage,
    required this.activity,
    this.message,
    this.scheduledAt,
    this.expiresAt,
    required this.myStatus,
  });

  final int flashId;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImage;
  final Activity activity;
  final String? message;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  /// PENDING(아직 합류 안 함) | JOINED
  final String myStatus;

  bool get joined => myStatus == 'JOINED';

  factory ReceivedFlash.fromJson(Map<String, dynamic> json) => ReceivedFlash(
        flashId: json['flashId'] as int,
        senderId: json['senderId'] as int,
        senderNickname: json['senderNickname'] as String,
        senderProfileImage: json['senderProfileImage'] as String?,
        activity: Activity.fromWire(json['activity'] as String?),
        message: json['message'] as String?,
        scheduledAt: _parseDate(json['scheduledAt']),
        expiresAt: _parseDate(json['expiresAt']),
        myStatus: json['myStatus'] as String? ?? 'PENDING',
      );
}

/// POST /api/flashes 응답.
/// { flashId, roomId, activity, scheduledAt, expiresAt, recipientCount }
class FlashCreated {
  const FlashCreated({
    required this.flashId,
    required this.roomId,
    required this.activity,
    this.scheduledAt,
    this.expiresAt,
    required this.recipientCount,
  });

  final int flashId;
  final int roomId;
  final Activity activity;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final int recipientCount;

  factory FlashCreated.fromJson(Map<String, dynamic> json) => FlashCreated(
        flashId: json['flashId'] as int,
        roomId: json['roomId'] as int,
        activity: Activity.fromWire(json['activity'] as String?),
        scheduledAt: _parseDate(json['scheduledAt']),
        expiresAt: _parseDate(json['expiresAt']),
        recipientCount: json['recipientCount'] as int? ?? 0,
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v as String);
}

/// GET /api/flashes/sent 항목 — 내가 띄운 활성 번개(홈 배너용).
/// joinedMembers = 합류자만(보낸 사람 제외).
class SentFlash {
  const SentFlash({
    required this.flashId,
    required this.activity,
    this.message,
    this.scheduledAt,
    this.expiresAt,
    required this.joined,
  });

  final int flashId;
  final Activity activity;
  final String? message;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  /// 합류자 (닉네임/프로필). 수 = "N명 모였어요".
  final List<({String nickname, String? profileImage})> joined;

  int get joinedCount => joined.length;

  factory SentFlash.fromJson(Map<String, dynamic> json) => SentFlash(
        flashId: json['flashId'] as int,
        activity: Activity.fromWire(json['activity'] as String?),
        message: json['message'] as String?,
        scheduledAt: _parseDate(json['scheduledAt']),
        expiresAt: _parseDate(json['expiresAt']),
        joined: (json['joinedMembers'] as List<dynamic>? ?? [])
            .map((e) => (
                  nickname: (e as Map)['nickname'] as String? ?? '친구',
                  profileImage: e['profileImage'] as String?,
                ))
            .toList(),
      );
}
