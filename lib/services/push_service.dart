import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../repositories/auth_repository.dart';

/// 앱이 꺼져 있을 때 도착한 푸시. 시스템이 알림을 대신 띄우므로 여기서는 아무것도 하지 않는다.
/// (top-level 함수여야 한다 — 별도 isolate 에서 실행되기 때문)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// FCM 배선.
///
/// 서버 → FCM → 기기 경로라 **우리 서버가 공개 URL 일 필요는 없다**(로컬 서버로도 푸시가 온다).
/// 기기토큰은 로그인한 뒤에 서버에 등록하고, 로그아웃 때 해제한다 —
/// 안 그러면 로그아웃한 기기로 남의 번개 알림이 간다.
class PushService {
  PushService(this._deviceTokens);

  final DeviceTokenRepository _deviceTokens;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// 알림 탭으로 열린 화면 라우팅용. { type: NEW_FLASH|MEMBER_JOINED|FRIEND_*, flashId: int }
  final ValueNotifier<Map<String, String>?> tapped = ValueNotifier(null);

  /// 친구 관계가 바뀌었다는 신호(신청 도착·수락됨). 앱이 떠 있을 때 배지를 바로 갱신하려고 둔다 —
  /// 알림만 오고 숫자가 그대로면 알림이 거짓말처럼 보인다.
  final ValueNotifier<int> friendsChanged = ValueNotifier(0);

  /// 서버에 등록해 둔 토큰. 로그아웃 때 이 값으로 해제한다.
  String? _registeredToken;
  bool _handlersAttached = false;

  /// 포그라운드 표시용 채널. Android 8+ 는 채널이 없으면 알림이 안 뜬다.
  static const _channel = AndroidNotificationChannel(
    'tuk_flash',
    '툭 알림',
    description: '친구가 툭 띄웠을 때 알려줘요',
    importance: Importance.high,
  );

  /// 로그인 직후 호출. 권한 → 토큰 → 서버 등록 → 리스너.
  /// 실패해도 앱은 그대로 쓸 수 있어야 하므로 예외를 밖으로 던지지 않는다.
  Future<void> start() async {
    try {
      await _ensureLocalPlugin();

      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // 사용자가 거절 — 앱 안에서 배너로는 계속 보인다(STOMP)
        debugPrint('[tuk] 알림 권한 거절됨');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);

      if (!_handlersAttached) {
        _handlersAttached = true;
        // 앱이 떠 있을 때 iOS 가 알림을 직접 띄우면 _showForeground 와 겹쳐 두 번 뜬다.
        // 표시는 아래 onMessage 한 곳에서만 — 안드로이드와 같은 경로로 맞춘다.
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
        // 토큰은 앱 재설치·데이터 삭제 등으로 갱신된다 → 그때마다 다시 등록
        FirebaseMessaging.instance.onTokenRefresh.listen(_register);
        FirebaseMessaging.onMessage.listen((m) {
          _showForeground(m);
          if ((m.data['type'] ?? '').startsWith('FRIEND_')) {
            friendsChanged.value++;
          }
        });
        FirebaseMessaging.onMessageOpenedApp.listen((m) => tapped.value = m.data.cast<String, String>());
        // 종료 상태에서 알림을 탭해 열린 경우
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) tapped.value = initial.data.cast<String, String>();
      }
    } catch (e) {
      debugPrint('[tuk] 푸시 초기화 실패: $e');
    }
  }

  /// 로그아웃 시. 서버에서 이 기기 토큰을 지운다.
  Future<void> stop() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _deviceTokens.unregister(token);
    } catch (e) {
      debugPrint('[tuk] 기기토큰 해제 실패: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _deviceTokens.register(token, platform: _platform);
      _registeredToken = token;
    } catch (e) {
      debugPrint('[tuk] 기기토큰 등록 실패: $e');
    }
  }

  String get _platform {
    try {
      return Platform.isIOS ? 'IOS' : 'ANDROID';
    } catch (_) {
      return 'ANDROID';
    }
  }

  /// 앱이 떠 있을 때는 시스템이 알림을 안 띄워준다 → 직접 띄운다.
  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: message.data['flashId'],
    );
  }

  Future<void> _ensureLocalPlugin() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS 설정이 없으면 앱이 떠 있을 때 알림이 아예 안 뜬다.
        // 권한은 바로 뒤에서 FirebaseMessaging 이 물어보므로 여기서는 묻지 않는다(팝업 두 번 방지).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }
}
