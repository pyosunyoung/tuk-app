import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/map_links.dart';

/// 외부 지도 앱 열기 + 마지막으로 고른 지도 앱 기억.
class MapLauncher {
  const MapLauncher();

  static const _prefKey = 'last_map_app';

  Future<MapApp?> lastUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return MapApp.fromStorageKey(prefs.getString(_prefKey));
    } catch (_) {
      return null; // 기억 못 해도 시트는 정상 동작
    }
  }

  /// 앱 딥링크 → 실패하면 웹 지도. 둘 다 못 열면 false.
  Future<bool> open(
    MapApp app, {
    required String placeName,
    double? lat,
    double? lng,
  }) async {
    final link = buildMapLink(app, placeName: placeName, lat: lat, lng: lng);

    final opened = await _tryLaunch(link.app) || await _tryLaunch(link.web);
    if (opened) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, app.storageKey);
      } catch (_) {/* 기억은 부가 기능 */}
    }
    return opened;
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      // 앱이 없으면 false 를 돌려주거나 예외를 던진다(플랫폼·버전마다 다름) → 둘 다 실패로 본다
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (e) {
      debugPrint('[tuk] 지도 열기 실패 $uri: ${e.code}');
      return false;
    }
  }
}
