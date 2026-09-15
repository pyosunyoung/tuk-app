import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// 앱 전역 설정. 백엔드 접속 주소는 실행 대상에 따라 다르다.
/// - Android 에뮬레이터: 호스트 localhost = 10.0.2.2
/// - iOS 시뮬레이터 / 웹 / 데스크톱: localhost
class AppConfig {
  const AppConfig._();

  /// 실기기 테스트용 오버라이드. 실기기는 10.0.2.2(에뮬레이터 전용 별칭)에 닿지 못하므로
  /// 개발 PC 의 LAN IP 를 넣어준다:
  ///   flutter run --dart-define=API_HOST=192.168.0.10
  static const String _hostOverride = String.fromEnvironment('API_HOST');

  /// 배포 서버용 오버라이드. 스킴까지 포함한 전체 origin 을 넣는다(포트 8080 을 붙이지 않음).
  /// 운영은 Caddy 가 443 에서 HTTPS 를 종단하므로 API_HOST 방식(http://host:8080)으론 못 붙는다.
  ///   flutter run --dart-define=API_BASE_URL=https://tuk.158-247-230-36.sslip.io
  /// 지정하면 API_HOST 보다 우선하고, 웹소켓은 https→wss 로 유도한다.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get _host {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    if (kIsWeb) return 'localhost';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {
      // Platform 접근 불가 환경(웹)에서는 위 kIsWeb 에서 처리됨
    }
    return 'localhost';
  }

  static String get baseUrl =>
      _baseUrlOverride.isNotEmpty ? _baseUrlOverride : 'http://$_host:8080';

  /// STOMP 웹소켓 엔드포인트 (SockJS 아님 — 네이티브 ws)
  static String get wsUrl => _baseUrlOverride.isNotEmpty
      ? '${_baseUrlOverride.replaceFirst(RegExp(r'^http'), 'ws')}/ws'
      : 'ws://$_host:8080/ws';

  static const String apiPrefix = '/api';
}

/// 카카오 로그인 설정.
///
/// 네이티브 앱 키는 **비밀키가 아니다** — 어차피 배포된 앱 바이너리에 들어간다.
/// 실제 보호는 카카오 콘솔에 등록한 **키 해시(Android) / 번들 ID(iOS)** 가 한다.
/// (다른 앱이 키를 베껴도 키 해시가 달라 로그인 안 됨)
///
/// 키를 바꾸면 아래 세 곳을 같이 바꿔야 한다:
///  1. 이 파일 — Dart SDK 초기화
///  2. `android/app/src/main/AndroidManifest.xml` — `kakao{키}://oauth` 리다이렉트
///  3. `ios/Runner/Info.plist` — `CFBundleURLSchemes`
class KakaoConfig {
  const KakaoConfig._();

  /// 카카오 개발자 콘솔 > 내 애플리케이션 > 앱 키 > **네이티브 앱 키**.
  /// CI 등에서 덮어쓰려면 `--dart-define=KAKAO_NATIVE_APP_KEY=...`.
  static const String nativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: 'e0a9fa462f80243f11b982ca83b15bf8',
  );

  /// 키가 비어 있으면(빈 값으로 덮어쓴 경우) 카카오 로그인을 시도조차 하지 않는다.
  static bool get isConfigured => nativeAppKey.isNotEmpty;
}
