import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../core/config.dart';

/// 카카오 로그인 실패(취소 제외). 사용자에게 보여줄 문구를 담는다.
class KakaoLoginException implements Exception {
  const KakaoLoginException(this.message);

  final String message;

  @override
  String toString() => 'KakaoLoginException: $message';
}

/// 카카오 네이티브 SDK 래퍼.
///
/// 앱은 여기서 받은 **카카오 access token** 을 백엔드에 넘기고
/// (`POST /api/auth/login {provider:"kakao", token}`), 백엔드가 카카오에 검증한 뒤
/// 우리 세션(JWT)을 발급한다. 카카오 토큰 자체는 저장하지 않는다.
class KakaoAuthService {
  const KakaoAuthService();

  /// 카카오톡이 깔려 있으면 카카오톡으로, 아니면 카카오계정(웹)으로 로그인.
  ///
  /// - 성공: 카카오 access token
  /// - 사용자가 취소: `null` (실패가 아니므로 조용히 종료)
  /// - 그 외 실패: [KakaoLoginException]
  Future<String?> login() async {
    if (!KakaoConfig.isConfigured) {
      throw const KakaoLoginException('카카오 앱 키가 설정되지 않았어요.');
    }

    try {
      if (await isKakaoTalkInstalled()) {
        try {
          final token = await UserApi.instance.loginWithKakaoTalk();
          return token.accessToken;
        } catch (e) {
          if (_isCancelled(e)) return null;
          // 카카오톡은 있는데 실패(로그인 안 된 카톡 등) → 카카오계정으로 폴백
        }
      }
      final token = await UserApi.instance.loginWithKakaoAccount();
      return token.accessToken;
    } catch (e) {
      if (_isCancelled(e)) return null;
      throw KakaoLoginException(_messageFor(e));
    }
  }

  /// 카카오 세션 정리. 우리 세션(JWT) 로그아웃과 별개라 실패해도 무시한다.
  Future<void> logout() async {
    if (!KakaoConfig.isConfigured) return;
    try {
      await UserApi.instance.logout();
    } catch (_) {
      // 카카오 토큰이 이미 없거나 네트워크 실패 — 우리 세션 정리에 영향 없음
    }
  }

  /// 취소는 세 갈래로 온다: SDK 자체 취소, 네이티브(뒤로가기/창 닫기), 동의화면 거부.
  bool _isCancelled(Object e) =>
      (e is KakaoClientException && e.reason == ClientErrorCause.cancelled) ||
      (e is PlatformException && e.code == 'CANCELED') ||
      (e is KakaoAuthException && e.error == AuthErrorCause.accessDenied);

  String _messageFor(Object e) {
    if (e is KakaoAuthException &&
        (e.error == AuthErrorCause.invalidClient ||
            e.error == AuthErrorCause.misconfigured)) {
      // 키 해시·플랫폼 미등록 등 우리 쪽 설정 문제. 사용자가 할 수 있는 일이 없으므로
      // 화면에는 일반 문구만 보여주고, 단서는 로그로 남긴다.
      debugPrint('[tuk] 카카오 앱 설정 문제(키 해시/앱 키 확인): $e');
    }
    return '카카오 로그인에 실패했어요. 잠시 후 다시 시도해 주세요';
  }
}
