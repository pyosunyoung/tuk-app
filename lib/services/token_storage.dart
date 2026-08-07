import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// access/refresh 토큰을 안전 저장소에 보관.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  // 잦은 접근을 위한 인메모리 캐시 (인터셉터 동기 접근용)
  String? _accessCache;
  String? _refreshCache;

  String? get accessToken => _accessCache;
  String? get refreshToken => _refreshCache;

  /// 앱 시작 시 1회 호출 — 저장된 토큰을 캐시로 로드.
  Future<void> load() async {
    _accessCache = await _storage.read(key: _kAccess);
    _refreshCache = await _storage.read(key: _kRefresh);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessCache = accessToken;
    _refreshCache = refreshToken;
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  bool get hasSession => _refreshCache != null;
}
