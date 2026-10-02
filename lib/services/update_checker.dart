import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';

/// 서버의 최신 버전 정보(public/app-version.json).
class AppVersionInfo {
  const AppVersionInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minBuild,
    this.downloadUrl,
    this.notes,
  });

  final String latestVersion;
  final int latestBuild;

  /// 이보다 낮은 빌드는 서버와 안 맞을 수 있다 → 매번 안내한다.
  final int minBuild;

  /// 받을 곳. 아직 없으면(카톡으로 직접 나눠주는 동안) null.
  final String? downloadUrl;
  final String? notes;

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) => AppVersionInfo(
        latestVersion: json['latestVersion'] as String? ?? '',
        latestBuild: json['latestBuild'] as int? ?? 0,
        minBuild: json['minBuild'] as int? ?? 0,
        downloadUrl: json['downloadUrl'] as String?,
        notes: json['notes'] as String?,
      );
}

/// 안내할 업데이트. [required] 면 지금 버전이 너무 오래됐다.
class PendingUpdate {
  const PendingUpdate(this.info, {required this.required});
  final AppVersionInfo info;
  final bool required;
}

/// 새 버전 확인. APK 를 직접 나눠주는 동안은 스토어가 알려주지 않으니 앱이 스스로 묻는다.
///
/// 같은 버전 안내는 **한 번만** 한다(재촉하지 않는 앱). 단, 지금 버전이 minBuild 보다
/// 낮으면 동작이 깨질 수 있어 켤 때마다 안내한다.
/// 확인 실패(오프라인 등)는 조용히 넘긴다 — 업데이트 안내 때문에 앱 쓰는 걸 막지 않는다.
class UpdateChecker {
  UpdateChecker({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  final Dio _dio;
  static const _seenKey = 'update_seen_build';

  Future<PendingUpdate?> check() async {
    try {
      final res = await _dio.get('${ShareConfig.webBase}/app-version.json');
      final data = res.data is Map ? res.data as Map : null;
      if (data == null) return null;
      final info = AppVersionInfo.fromJson(data.cast<String, dynamic>());
      final current = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      return decide(info, current, await _seenBuild());
    } catch (e) {
      debugPrint('[tuk] 버전 확인 실패 — 건너뜀: $e');
      return null;
    }
  }

  /// 안내 여부만 따로 — 테스트하려고 순수 함수로 뺐다.
  static PendingUpdate? decide(AppVersionInfo info, int currentBuild, int? seenBuild) {
    if (currentBuild < info.minBuild) return PendingUpdate(info, required: true);
    if (info.latestBuild > currentBuild && seenBuild != info.latestBuild) {
      return PendingUpdate(info, required: false);
    }
    return null;
  }

  /// 안내를 봤다고 기록(같은 버전은 다시 안 띄운다).
  Future<void> markSeen(int build) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_seenKey, build);
    } catch (_) {}
  }

  Future<int?> _seenBuild() async {
    try {
      return (await SharedPreferences.getInstance()).getInt(_seenKey);
    } catch (_) {
      return null;
    }
  }
}
