import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// 인증/세션 상태의 단일 진실원.
/// 실시간(STOMP) 연결은 여기서 책임지지 않는다 — 프레즌스/번개 기능이
/// 로그인 상태를 보고 스스로 붙는다(결합 최소화).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required TokenStorage tokens,
    required AuthRepository auth,
  })  : _tokens = tokens,
        _auth = auth;

  final TokenStorage _tokens;
  final AuthRepository _auth;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  /// 앱 시작 시 1회. 저장된 세션이 있으면 곧바로 로그인 상태로.
  Future<void> bootstrap() async {
    await _tokens.load();
    _status = _tokens.hasSession ? AuthStatus.loggedIn : AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> login({required String provider, required String token}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final tokens = await _auth.login(provider: provider, token: token);
      await _tokens.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      _status = AuthStatus.loggedIn;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = '로그인 중 문제가 발생했어요. 서버가 켜져 있는지 확인해주세요.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // 로그아웃 실패해도 로컬 세션은 정리
    }
    await _finishLogout();
  }

  /// refresh 실패 등으로 세션이 죽었을 때 ApiClient 가 호출.
  Future<void> onSessionExpired() async {
    await _finishLogout();
  }

  Future<void> _finishLogout() async {
    await _tokens.clear();
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
