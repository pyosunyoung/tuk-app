import '../core/config.dart';
import '../models/flash.dart';
import '../models/meetup_room.dart';
import '../models/place.dart';
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

  /// 내가 던진 활성 툭(홈 배너용).
  Future<List<SentFlash>> sent() async {
    final data = await _api.get('$_base/sent');
    return (data as List)
        .map((e) => SentFlash.fromJson((e as Map).cast<String, dynamic>()))
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

  /// 장소 설정. 직접 입력이면 이름만, 검색 장소면 좌표·카카오 ID·주소까지.
  /// 항상 전부 보낸다 — 서버는 통째로 교체하므로 직접 입력으로 바꾸면 이전 가게 정보가 지워진다.
  Future<MeetupRoom> setPlace(int flashId, Place place) async {
    final data = await _api.patch('$_base/$flashId/room/place', body: {
      'placeName': place.name,
      'placeLat': place.lat,
      'placeLng': place.lng,
      'kakaoPlaceId': place.kakaoPlaceId,
      'placeAddress': place.address,
    });
    return MeetupRoom.fromJson((data as Map).cast<String, dynamic>());
  }
}
