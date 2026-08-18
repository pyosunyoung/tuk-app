import '../core/config.dart';
import '../models/flash.dart';
import '../models/meetup_room.dart';
import '../services/api_client.dart';

class FlashRepository {
  FlashRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/flashes';

  /// 번개 발송. targetUserIds 비우면 절친 전체. scheduledAt null=지금.
  Future<FlashCreated> send({
    required String activity,
    String? message,
    List<int>? targetUserIds,
    int durationMinutes = 60,
    DateTime? scheduledAt,
  }) async {
    final data = await _api.post(_base, body: {
      'activity': activity,
      if (message != null && message.isNotEmpty) 'message': message,
      if (targetUserIds != null) 'targetUserIds': targetUserIds,
      'durationMinutes': durationMinutes,
      'scheduledAt': scheduledAt?.toIso8601String(),
    });
    return FlashCreated.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 받은 활성 번개.
  Future<List<ReceivedFlash>> received() async {
    final data = await _api.get('$_base/received');
    return (data as List)
        .map((e) => ReceivedFlash.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// 합류 — 멱등. 모임방 반환.
  Future<MeetupRoom> join(int flashId) async {
    final data = await _api.post('$_base/$flashId/join');
    return MeetupRoom.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<MeetupRoom> room(int flashId) async {
    final data = await _api.get('$_base/$flashId/room');
    return MeetupRoom.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 장소 설정.
  Future<MeetupRoom> setPlace(
    int flashId, {
    required String placeName,
    double? placeLat,
    double? placeLng,
  }) async {
    final data = await _api.patch('$_base/$flashId/room/place', body: {
      'placeName': placeName,
      'placeLat': placeLat,
      'placeLng': placeLng,
    });
    return MeetupRoom.fromJson((data as Map).cast<String, dynamic>());
  }
}
