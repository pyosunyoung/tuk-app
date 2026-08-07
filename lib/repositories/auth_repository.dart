import '../core/config.dart';
import '../models/auth_tokens.dart';
import '../services/api_client.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/auth';

  /// 소셜/dev 로그인. provider 대소문자 무관.
  Future<AuthTokens> login({required String provider, required String token}) async {
    final data = await _api.post(
      '$_base/login',
      body: {'provider': provider, 'token': token},
      auth: false,
    );
    return AuthTokens.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> logout() async {
    await _api.post('$_base/logout');
  }
}

/// FCM 기기토큰 등록/해제.
class DeviceTokenRepository {
  DeviceTokenRepository(this._api);

  final ApiClient _api;
  static const _base = '${AppConfig.apiPrefix}/device-tokens';

  Future<void> register(String token, {String platform = 'ANDROID'}) async {
    await _api.post(_base, body: {'token': token, 'platform': platform});
  }

  Future<void> unregister(String token) async {
    await _api.delete(_base, body: {'token': token});
  }
}
