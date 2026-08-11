import 'activity.dart';

/// GET /api/presence/me → { available, activity, remainingSeconds }
/// (없으면 available:false, 나머지 null)
class MyPresence {
  const MyPresence({
    required this.available,
    this.activity,
    this.remainingSeconds,
  });

  final bool available;
  final Activity? activity;
  final int? remainingSeconds;

  factory MyPresence.off() => const MyPresence(available: false);

  factory MyPresence.fromJson(Map<String, dynamic> json) => MyPresence(
        available: json['available'] as bool? ?? false,
        activity: json['activity'] == null
            ? null
            : Activity.fromWire(json['activity'] as String),
        remainingSeconds: json['remainingSeconds'] as int?,
      );
}

/// GET /api/presence/friends 항목 — 지금 한가한 친구.
/// { userId, nickname, profileImage, activity, remainingSeconds }
class FriendPresence {
  const FriendPresence({
    required this.userId,
    required this.nickname,
    this.profileImage,
    required this.activity,
    required this.remainingSeconds,
  });

  final int userId;
  final String nickname;
  final String? profileImage;
  final Activity activity;
  final int remainingSeconds;

  factory FriendPresence.fromJson(Map<String, dynamic> json) => FriendPresence(
        userId: json['userId'] as int,
        nickname: json['nickname'] as String,
        profileImage: json['profileImage'] as String?,
        activity: Activity.fromWire(json['activity'] as String?),
        remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      );
}
