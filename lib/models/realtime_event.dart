import 'activity.dart';

/// /user/queue/presence 이벤트 (PresenceEvent)
/// type: AVAILABLE(콜 켬) | UNAVAILABLE(콜 끔 — 활동/프로필 null)
class PresenceEvent {
  const PresenceEvent({
    required this.type,
    required this.userId,
    this.nickname,
    this.profileImage,
    this.activity,
    this.remainingSeconds,
  });

  final String type;
  final int userId;
  final String? nickname;
  final String? profileImage;
  final Activity? activity;
  final int? remainingSeconds;

  bool get isAvailable => type == 'AVAILABLE';

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        type: json['type'] as String,
        userId: json['userId'] as int,
        nickname: json['nickname'] as String?,
        profileImage: json['profileImage'] as String?,
        activity: json['activity'] == null
            ? null
            : Activity.fromWire(json['activity'] as String),
        remainingSeconds: json['remainingSeconds'] as int?,
      );
}

/// /user/queue/flash 이벤트 (FlashPushEvent)
/// type: NEW_FLASH(새 번개 — userId=보낸이) | MEMBER_JOINED(누가 합류 — userId=합류자)
class FlashPushEvent {
  const FlashPushEvent({
    required this.type,
    required this.flashId,
    required this.userId,
    this.nickname,
    this.profileImage,
    this.activity,
    this.message,
    this.scheduledAt,
    this.expiresAt,
  });

  final String type;
  final int flashId;
  final int userId;
  final String? nickname;
  final String? profileImage;
  final Activity? activity;
  final String? message;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  bool get isNewFlash => type == 'NEW_FLASH';
  bool get isMemberJoined => type == 'MEMBER_JOINED';

  factory FlashPushEvent.fromJson(Map<String, dynamic> json) => FlashPushEvent(
        type: json['type'] as String,
        flashId: json['flashId'] as int,
        userId: json['userId'] as int,
        nickname: json['nickname'] as String?,
        profileImage: json['profileImage'] as String?,
        activity: json['activity'] == null
            ? null
            : Activity.fromWire(json['activity'] as String),
        message: json['message'] as String?,
        scheduledAt: json['scheduledAt'] == null
            ? null
            : DateTime.tryParse(json['scheduledAt'] as String),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );
}
