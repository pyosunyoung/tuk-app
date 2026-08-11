import '../core/config.dart';
import '../models/presence.dart';
import '../services/api_client.dart';

class PresenceRepository {
  PresenceRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/presence';

  /// 지금 한가한 친구 목록.
  Future<List<FriendPresence>> availableFriends() async {
    final data = await _api.get('$_base/friends');
    return (data as List)
        .map((e) => FriendPresence.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// 내 콜 상태.
  Future<MyPresence> me() async {
    final data = await _api.get('$_base/me');
    return MyPresence.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 콜 켜기. durationMinutes 1~720.
  Future<MyPresence> turnOn({
    required String activity,
    required int durationMinutes,
  }) async {
    final data = await _api.post(
      _base,
      body: {'activity': activity, 'durationMinutes': durationMinutes},
    );
    return MyPresence.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 콜 끄기.
  Future<void> turnOff() async {
    await _api.delete(_base);
  }
}
