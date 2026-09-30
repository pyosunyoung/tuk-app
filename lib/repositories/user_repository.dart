import '../core/config.dart';
import '../models/me.dart';
import '../services/api_client.dart';

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/users';

  /// 내 정보. 로그인 직후 1회 받아 세션 동안 들고 있는다.
  Future<Me> me() async {
    final data = await _api.get('$_base/me');
    return Me.fromJson((data as Map).cast<String, dynamic>());
  }

  /// 탈퇴. 서버가 내 툭·모임방·친구 관계·기기 토큰을 지운다(되돌릴 수 없음).
  Future<void> deleteMe() => _api.delete('$_base/me');
}
