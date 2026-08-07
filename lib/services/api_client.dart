import 'dart:async';

import 'package:dio/dio.dart';

import '../core/config.dart';
import '../models/auth_tokens.dart';
import 'token_storage.dart';

/// 백엔드 공통 에러 포맷 { "message": "..." } 을 감싼 예외.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// dio 래퍼.
/// - baseUrl = 10.0.2.2:8080 (안드 에뮬레이터)
/// - Authorization: Bearer 자동 첨부
/// - 401 → refresh(rotation) → 원요청 1회 재시도. 동시 401 은 single-flight.
class ApiClient {
  ApiClient(this._tokens, {required this.onSessionExpired}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      // 4xx/5xx 를 예외로 던지지 않고 우리가 직접 처리
      validateStatus: (_) => true,
    ));
    // refresh 전용 — 인터셉터 재귀 방지용 별도 인스턴스
    _refreshDio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      contentType: Headers.jsonContentType,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokens.accessToken;
        if (token != null && options.extra['skipAuth'] != true) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final TokenStorage _tokens;

  /// refresh 마저 실패(=세션 만료)했을 때 호출 — 강제 로그아웃 처리용.
  final Future<void> Function() onSessionExpired;

  late final Dio _dio;
  late final Dio _refreshDio;

  // 동시 다발 401 을 하나의 refresh 로 합치기 위한 single-flight
  Future<bool>? _refreshing;

  // ---- 공개 HTTP 메서드 ------------------------------------------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  // ---- 내부 ------------------------------------------------------------

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    Response res = await _dio.request(
      path,
      data: body,
      queryParameters: query,
      options: Options(method: method, extra: {'skipAuth': !auth}),
    );

    // access 만료 → refresh 후 1회 재시도
    if (res.statusCode == 401 && auth && _tokens.refreshToken != null) {
      final ok = await _ensureRefreshed();
      if (ok) {
        res = await _dio.request(
          path,
          data: body,
          queryParameters: query,
          options: Options(method: method),
        );
      }
    }

    return _unwrap(res);
  }

  /// single-flight refresh. 이미 진행 중이면 그 결과를 기다린다.
  Future<bool> _ensureRefreshed() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _refreshDio.post(
        '${AppConfig.apiPrefix}/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (res.statusCode == 200 && res.data is Map) {
        final tokens = AuthTokens.fromJson((res.data as Map).cast<String, dynamic>());
        await _tokens.save(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        return true;
      }
    } on DioException catch (_) {
      // 네트워크/서버 오류 — 세션 유지, 아래에서 만료 처리 안 함
      return false;
    }
    // refresh 무효 → 세션 만료
    await onSessionExpired();
    return false;
  }

  dynamic _unwrap(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return res.data;
    }
    throw ApiException(code, _extractMessage(res.data, code));
  }

  String _extractMessage(dynamic data, int code) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return switch (code) {
      401 => '로그인이 필요합니다.',
      403 => '권한이 없습니다.',
      404 => '찾을 수 없습니다.',
      502 => '외부 서비스 오류입니다. 잠시 후 다시 시도해주세요.',
      _ => '요청을 처리하지 못했습니다. ($code)',
    };
  }
}
