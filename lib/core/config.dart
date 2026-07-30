import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// 앱 전역 설정. 백엔드 접속 주소는 실행 대상에 따라 다르다.
/// - Android 에뮬레이터: 호스트 localhost = 10.0.2.2
/// - iOS 시뮬레이터 / 웹 / 데스크톱: localhost
class AppConfig {
  const AppConfig._();

  static String get _host {
    if (kIsWeb) return 'localhost';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {
      // Platform 접근 불가 환경(웹)에서는 위 kIsWeb 에서 처리됨
    }
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:8080';

  /// STOMP 웹소켓 엔드포인트 (SockJS 아님 — 네이티브 ws)
  static String get wsUrl => 'ws://$_host:8080/ws';

  static const String apiPrefix = '/api';
}
