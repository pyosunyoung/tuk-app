import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

import '../core/deep_link.dart';

/// 카카오톡 공유 카드로 앱이 열릴 때의 링크를 받아 [pending] 에 올려 둔다.
/// 실제 이동은 홈 화면([DeepLinkHandler])이 로그인된 뒤에 한다.
///
/// 두 경로로 받는다:
///  - 앱이 켜져 있을 때: 카카오 SDK 의 [receiveKakaoScheme] 콜백
///  - 앱이 꺼져 있다가 카드로 켜질 때(콜드 스타트): 네이티브에 직접 물어본다.
///    카카오 SDK 는 이때 Dart 쪽 준비 전에 링크를 보내버려 유실될 수 있다(플러그인 소스로 확인).
///    네이티브 쪽 구현은 안드로이드 `MainActivity.kt`, iOS `AppDelegate.swift`(TukDeepLink).
class DeepLinkService {
  static const _channel = MethodChannel('com.tuk.app/deeplink');

  final pending = ValueNotifier<TukLink?>(null);

  String? _lastUrl;
  DateTime? _lastAt;

  Future<void> start() async {
    receiveKakaoScheme(_accept);
    try {
      final initial = await _channel.invokeMethod<String>('initialLink');
      if (initial != null) _accept(Uri.parse(initial));
    } on MissingPluginException {
      // 채널이 없는 플랫폼(데스크톱·웹 등) — SDK 콜백만 쓴다
    } catch (e) {
      debugPrint('[tuk] 초기 딥링크 조회 실패: $e');
    }
  }

  void _accept(Uri uri) {
    // 콜드 스타트엔 SDK 콜백과 직접 조회가 같은 링크를 두 번 줄 수 있다
    final url = uri.toString();
    final now = DateTime.now();
    if (url == _lastUrl && _lastAt != null && now.difference(_lastAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastUrl = url;
    _lastAt = now;

    final link = TukLink.parse(uri);
    if (link != null) pending.value = link;
  }

  /// 처리할 링크를 꺼낸다(한 번만 처리되게 비운다).
  TukLink? take() {
    final link = pending.value;
    pending.value = null;
    return link;
  }
}
