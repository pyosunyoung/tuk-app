import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/config.dart';
import '../models/realtime_event.dart';

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

  void connect(String accessToken) {
    // 재연결 시 기존 세션 정리
    disconnect();

    final headers = {'Authorization': 'Bearer $accessToken'};
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        reconnectDelay: const Duration(seconds: 3),
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onWebSocketError: (dynamic e) {
          debugPrint('[stomp] ws error: $e');
          _connected.value = false;
        },
        onDisconnect: (_) => _connected.value = false,
        onStompError: (f) => debugPrint('[stomp] error: ${f.body}'),
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
