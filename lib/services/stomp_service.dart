import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/config.dart';
import '../models/realtime_event.dart';

/// 연결 직전에 쓸 access token 을 돌려준다(필요하면 갱신까지). 세션이 없으면 null.
/// [forceRefresh] 면 만료 판단 없이 갱신한다.
typedef AccessTokenProvider = Future<String?> Function({bool forceRefresh});

/// STOMP 웹소켓 — 로그인 후 1회 연결, 로그아웃 시 해제.
/// CONNECT 헤더의 JWT 로 인증. 구독:
///   /user/queue/presence  → PresenceEvent
///   /user/queue/flash     → FlashPushEvent
class StompService {
  StompClient? _client;

  final _presence = StreamController<PresenceEvent>.broadcast();
  final _flash = StreamController<FlashPushEvent>.broadcast();
  final _connected = ValueNotifier<bool>(false);

  Stream<PresenceEvent> get presenceEvents => _presence.stream;
  Stream<FlashPushEvent> get flashEvents => _flash.stream;
  ValueListenable<bool> get connected => _connected;

  bool get isActive => _client?.connected ?? false;

  void connect(AccessTokenProvider accessToken) {
    // 재연결 시 기존 세션 정리
    disconnect();

    // ⚠️ 토큰을 connect() 시점에 한 번만 넣으면 안 된다.
    // access token 은 30분이면 만료되는데, 서버가 CONNECT 를 거부하면 클라이언트는
    // 같은 헤더로 3초마다 재연결만 반복한다(앱을 한동안 안 쓰다 켜면 실시간이 영영 안 붙던 버그).
    // stomp_dart_client 는 (재)연결마다 beforeConnect 를 먼저 부르고, CONNECT 프레임을 보낼 때
    // 이 맵을 읽는다 → 같은 맵 객체를 매번 새 토큰으로 채운다.
    final headers = <String, String>{};
    // 서버가 CONNECT 를 거부했으면 다음 연결 전엔 무조건 갱신한다.
    // (만료 판단은 기기 시계 기준이라, 기기 시계가 틀리면 만료된 토큰을 유효하다고 볼 수 있다 — 실제로 겪음)
    var rejected = false;
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        reconnectDelay: const Duration(seconds: 3),
        beforeConnect: () async {
          final token = await accessToken(forceRefresh: rejected);
          rejected = false;
          // null = 갱신 실패. 세션이 끝난 거면 로그아웃 흐름이 disconnect 하고,
          // 일시적 네트워크 문제면 다음 재연결 때 다시 시도된다.
          if (token != null) headers['Authorization'] = 'Bearer $token';
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onWebSocketError: (dynamic e) {
          debugPrint('[stomp] ws error: $e');
          _connected.value = false;
        },
        onDisconnect: (_) => _connected.value = false,
        onStompError: (f) {
          // 서버가 보내는 ERROR 프레임 — 이 서버에선 CONNECT 인증 거부가 사실상 유일한 경우
          debugPrint('[stomp] error: ${f.headers['message'] ?? f.body}');
          rejected = true;
        },
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected.value = true;
    _client?.subscribe(
      destination: '/user/queue/presence',
      callback: (f) => _emit(f.body, (m) => _presence.add(PresenceEvent.fromJson(m))),
    );
    _client?.subscribe(
      destination: '/user/queue/flash',
      callback: (f) => _emit(f.body, (m) => _flash.add(FlashPushEvent.fromJson(m))),
    );
  }

  void _emit(String? body, void Function(Map<String, dynamic>) parse) {
    if (body == null || body.isEmpty) return;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) parse(decoded);
    } catch (e) {
      debugPrint('[stomp] parse fail: $e / $body');
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _connected.value = false;
  }

  void dispose() {
    disconnect();
    _presence.close();
    _flash.close();
    _connected.dispose();
  }
}
