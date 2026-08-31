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
}
