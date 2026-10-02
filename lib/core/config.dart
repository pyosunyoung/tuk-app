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

  /// 운영 서버. 릴리스 빌드는 아무 옵션 없이 빌드해도 여기로 붙는다.
  /// (예전엔 기본값이 에뮬레이터용 10.0.2.2 라, 빌드 옵션 하나 빠뜨리면 친구 폰에서 로그인부터 안 됐다)
  static const String prodBaseUrl = 'https://tuk.158-247-230-36.sslip.io';

  /// 우선순위: API_BASE_URL 옵션 > 릴리스면 운영 > 개발이면 로컬(API_HOST 또는 에뮬레이터)
  static String get _origin {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kReleaseMode && _hostOverride.isEmpty) return prodBaseUrl;
    return 'http://$_host:8080';
  }

  static String get baseUrl => _origin;

  /// STOMP 웹소켓 엔드포인트 (SockJS 아님 — 네이티브 ws). https 면 wss.
  static String get wsUrl => '${_origin.replaceFirst(RegExp(r'^http'), 'ws')}/ws';

  static const String apiPrefix = '/api';
}

/// 카카오톡 공유 카드에 들어가는 웹 주소(카드 이미지, 앱이 없을 때 여는 안내 페이지).
///
/// 카드는 실제 친구에게 가므로 로컬 개발 중에도 **운영 주소**를 쓴다.
/// 이 도메인은 카카오 개발자 콘솔(툭 앱)의 사이트 도메인에 등록돼 있어야 카드 링크가 동작한다.
class ShareConfig {
  const ShareConfig._();

  static const String webBase = String.fromEnvironment(
    'SHARE_WEB_BASE',
    defaultValue: AppConfig.prodBaseUrl,
  );

  /// 카드 대표 이미지 (서버 Caddy 가 public/share/ 에서 제공). 카카오 권장 비율 2:1.
  static Uri get cardImage => Uri.parse('$webBase/share/tuk-card.png');
  static const int cardImageWidth = 800;
  static const int cardImageHeight = 400;

  /// 앱이 없는 사람이 모임방 카드를 눌렀을 때
  static Uri get appPage => Uri.parse('$webBase/app');

  /// 앱이 없는 사람이 초대 카드를 눌렀을 때 — 코드를 보여주고 설치를 안내
  static Uri invitePage(String code) =>
      Uri.parse('$webBase/invite').replace(queryParameters: {'code': code});

  /// 이용약관·개인정보 처리방침 (서버 public/ — 로컬 서버엔 없으니 개발 중에도 운영 주소)
  static Uri get termsPage => Uri.parse('$webBase/terms');
  static Uri get privacyPage => Uri.parse('$webBase/privacy');
}

/// 카카오 로그인 설정.
///
/// 네이티브 앱 키는 **비밀키가 아니다** — 어차피 배포된 앱 바이너리에 들어간다.
/// 실제 보호는 카카오 콘솔에 등록한 **키 해시(Android) / 번들 ID(iOS)** 가 한다.
/// (다른 앱이 키를 베껴도 키 해시가 달라 로그인 안 됨)
///
/// 키를 바꾸면 아래 곳들을 같이 바꿔야 한다:
///  1. 이 파일 — Dart SDK 초기화
///  2. `android/app/src/main/AndroidManifest.xml` — `kakao{키}://oauth`(로그인)·`kakao{키}://kakaolink`(공유 카드) 두 군데
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
