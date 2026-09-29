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
///     | PLACE_UPDATED / MEET_AT_UPDATED(장소·시간 정함/바꿈 — userId=정한 사람, before 가 null 이면 처음)
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
    this.placeBefore,
    this.placeAfter,
    this.meetAtBefore,
    this.meetAtAfter,
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
  final String? placeBefore;
  final String? placeAfter;
  final DateTime? meetAtBefore;
  final DateTime? meetAtAfter;

  bool get isNewFlash => type == 'NEW_FLASH';
  bool get isMemberJoined => type == 'MEMBER_JOINED';
  bool get isPlaceUpdated => type == 'PLACE_UPDATED';
  bool get isMeetAtUpdated => type == 'MEET_AT_UPDATED';

  /// 장소나 약속 시간이 정해지거나 바뀌었다 — 모임방·홈 목록을 다시 불러와야 한다.
  bool get isPlanUpdated => isPlaceUpdated || isMeetAtUpdated;

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
        expiresAt: _date(json['expiresAt']),
        placeBefore: json['placeBefore'] as String?,
        placeAfter: json['placeAfter'] as String?,
        meetAtBefore: _date(json['meetAtBefore']),
        meetAtAfter: _date(json['meetAtAfter']),
      );
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
