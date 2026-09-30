import 'package:flutter/foundation.dart';

import '../models/me.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_client.dart';
import '../services/kakao_auth_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// 인증/세션 상태의 단일 진실원.
/// 실시간(STOMP) 연결은 여기서 책임지지 않는다 — 프레즌스/번개 기능이
/// 로그인 상태를 보고 스스로 붙는다(결합 최소화).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required TokenStorage tokens,
    required AuthRepository auth,
    required UserRepository user,
    KakaoAuthService kakao = const KakaoAuthService(),
  })  : _tokens = tokens,
        _auth = auth,
        _user = user,
        _kakao = kakao;

  final TokenStorage _tokens;
  final AuthRepository _auth;
  final UserRepository _user;
  final KakaoAuthService _kakao;

  /// 내 정보. 로그인 상태에서만 채워진다(로드 전에는 null).
  Me? _me;
  Me? get me => _me;

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
    if (_status == AuthStatus.loggedIn) await _loadMe();
  }

  /// 내 정보 로드. 실패해도 세션은 유지한다(아바타만 이니셜로 나올 뿐).
  /// 단 404(탈퇴·DB 초기화)면 유효한 세션이 아니므로 정리한다.
  Future<void> _loadMe() async {
    try {
      _me = await _user.me();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _finishLogout();
        return;
      }
      // 세션은 살아있는데 내 정보만 못 받은 상태. 아바타가 이니셜 '나'로 나온다.
      debugPrint('[tuk] /users/me 실패 (${e.statusCode}): ${e.message}');
    } catch (e) {
      // 네트워크 일시 실패 — 다음 로그인/재시작 때 다시 시도된다
      debugPrint('[tuk] /users/me 실패: $e');
    }
  }

  /// 카카오 로그인. SDK로 카카오 토큰을 받아 백엔드 세션으로 바꾼다.
  /// 사용자가 취소하면 false + [error] == null — 화면은 토스트를 띄우지 않는다.
  Future<bool> loginWithKakao() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final kakaoToken = await _kakao.login();
      if (kakaoToken == null) return false; // 취소 — 조용히 되돌아간다
      return await _exchange(provider: 'kakao', token: kakaoToken);
    } on KakaoLoginException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// dev 로그인(로고 롱프레스) 및 테스트용 직접 로그인.
  Future<bool> login({required String provider, required String token}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await _exchange(provider: provider, token: token);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// 소셜 토큰 → 우리 세션(JWT) 교환 + 저장. busy/notify는 호출자가 관리.
  Future<bool> _exchange({
    required String provider,
    required String token,
  }) async {
    try {
      final tokens = await _auth.login(provider: provider, token: token);
      await _tokens.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      _status = AuthStatus.loggedIn;
      await _loadMe();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      // 연결 실패는 ApiClient 가 ApiException 으로 바꿔 위에서 잡힌다.
      // 여기 오는 건 예상 못 한 경우뿐이라, 사용자에겐 할 수 있는 일만 말한다.
      debugPrint('[tuk] 로그인 실패: $e');
      _error = '로그인하지 못했어요. 잠시 후 다시 시도해 주세요';
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // 로그아웃 실패해도 로컬 세션은 정리
    }
    await _kakao.logout(); // 다음 로그인 때 계정 선택부터 다시
    await _finishLogout();
  }

  /// 탈퇴. 서버 삭제가 실패하면 [ApiException] 을 그대로 던진다(세션 유지 — 다시 시도할 수 있게).
  /// 성공하면 카카오 연결을 끊고(실패 무시) 로그아웃과 같이 세션을 정리한다.
  Future<void> deleteAccount() async {
    await _user.deleteMe();
    await _kakao.unlink();
    await _finishLogout();
  }

  /// refresh 실패 등으로 세션이 죽었을 때 ApiClient 가 호출.
  Future<void> onSessionExpired() async {
    await _finishLogout();
  }

  Future<void> _finishLogout() async {
    _me = null;
    await _tokens.clear();
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
