import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/flash.dart';
import '../models/meetup_room.dart';
import '../repositories/flash_repository.dart';
import '../services/api_client.dart';

/// 번개 상태. (A: 발송·모임방·장소·합류. 받은 목록/실시간은 B에서 확장)
class FlashViewModel extends ChangeNotifier {
  FlashViewModel(this._repo);

  final FlashRepository _repo;

  /// 번개 발송. 성공 시 FlashCreated(방 생성됨, recipientCount 포함), 실패 시 throw.
  /// recipientCount == 0 은 실패가 아니다(방은 열림).
  Future<FlashCreated> send({
    required Activity activity,
    String? message,
    List<int>? targetUserIds,
    required int durationMinutes,
    DateTime? scheduledAt,
  }) {
    return _repo.send(
      activity: activity.wire,
      message: message,
      targetUserIds: targetUserIds,
      durationMinutes: durationMinutes,
      scheduledAt: scheduledAt,
    );
  }

  Future<MeetupRoom> room(int flashId) => _repo.room(flashId);

  /// 합류(멱등) → 모임방.
  Future<MeetupRoom> join(int flashId) => _repo.join(flashId);

  Future<MeetupRoom> setPlace(int flashId, String placeName) =>
      _repo.setPlace(flashId, placeName: placeName);

  /// ApiException 여부 헬퍼(끝난 번개 합류 등 문구 분기용).
  bool isEnded(Object e) =>
      e is ApiException && (e.statusCode == 400 || e.statusCode == 404);
}
