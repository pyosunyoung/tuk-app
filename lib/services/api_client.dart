import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/jwt.dart';
import '../models/auth_tokens.dart';
import 'token_storage.dart';

/// 서버에 닿지 못했을 때 사용자에게 보여줄 문구.
///
/// 사용자는 서버 사정을 알 수 없으므로 **직접 할 수 있는 일**만 말한다.
/// (예전엔 "서버가 켜져 있는지 확인해주세요" 라고 띄웠다 — 개발자용 문구가 제품에 남아 있었다)
String connectionMessageFor(DioExceptionType type) => switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        '응답이 너무 늦어요. 잠시 후 다시 시도해 주세요',
      _ => '지금 연결이 안 돼요. 인터넷 연결을 확인해 주세요',
    };

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
  ApiClient(
    this._tokens, {
    required this.onSessionExpired,
    @visibleForTesting HttpClientAdapter? adapter,
  }) {
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      // ⚠️ 여기도 필수. 기본값(2xx 만 정상)이면 refresh 401 이 DioException 으로 던져져
      // 아래 '네트워크 오류' 분기로 빠지고, 세션 만료 처리가 영영 안 된다(좀비 세션).
      validateStatus: (_) => true,
    ));
    // 테스트: 실제 네트워크 대신 가짜 서버로
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      _refreshDio.httpClientAdapter = adapter;
    }

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
    Response res = await _request(
      method,
      path,
      body: body,
      query: query,
      extra: {'skipAuth': !auth},
    );

    // access 만료 → refresh 후 1회 재시도
    if (res.statusCode == 401 && auth && _tokens.refreshToken != null) {
      final ok = await _ensureRefreshed();
      if (ok) {
        res = await _request(method, path, body: body, query: query);
      }
    }

    return _unwrap(res);
  }

  /// 서버에 닿지 못한 경우(끊긴 네트워크·응답 없음)를 [ApiException] 으로 바꾼다.
  ///
  /// 이걸 안 하면 DioException 이 그대로 화면까지 올라가고, 뷰모델마다 제각각 문구를
  /// 지어내게 된다. 실제로 로그인 화면은 "서버가 켜져 있는지 확인해주세요" 라는
  /// 개발자용 문구를 띄우고 있었다 — 사용자는 서버가 뭔지도, 어떻게 확인하는지도 모른다.
  Future<Response> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? extra,
  }) async {
    try {
      return await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, extra: extra),
      );
    } on DioException catch (e) {
      throw ApiException(null, connectionMessageFor(e.type));
    }
  }



  /// HTTP 가 아닌 곳(STOMP CONNECT)에 실을 access token.
  ///
  /// HTTP 요청은 401 을 받은 뒤 갱신하면 되지만, STOMP 는 거부되면 같은 헤더로 재연결만 반복한다.
  /// 그래서 연결 직전에 만료(또는 1분 내 만료)를 미리 확인하고 갱신한다.
  /// 갱신은 HTTP 와 같은 single-flight 를 공유 → 동시에 불려도 refresh rotation 이 한 번만 일어난다.
  /// 세션이 끝났으면(refresh 실패) null.
  ///
  /// [forceRefresh]: 만료 판단은 기기 시계로 하므로, 기기 시계가 틀리면 "아직 유효"로 오판할 수 있다.
  /// 서버가 이미 거부한 뒤라면 시계를 믿지 말고 갱신한다.
  Future<String?> validAccessToken({bool forceRefresh = false}) async {
    final token = _tokens.accessToken;
    if (!forceRefresh && token != null && !jwtExpiresSoon(token)) return token;
    if (_tokens.refreshToken == null) return null;
    final ok = await _ensureRefreshed();
    return ok ? _tokens.accessToken : null;
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
      // 5xx 는 서버 사정 — 토큰이 무효라는 뜻이 아니므로 세션 유지
      if ((res.statusCode ?? 0) >= 500) return false;
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
    debugPrint('[tuk] ${res.requestOptions.method} ${res.requestOptions.path} → $code');
    throw ApiException(code, _extractMessage(res.data, code));
  }

  /// 서버가 message 를 줬으면 그대로 쓴다. 없을 때의 폴백은 앱 말투(해요체)에 맞추고,
  /// 상태 코드 같은 내부 사정은 화면에 내보내지 않는다(로그에는 남긴다).
  String _extractMessage(dynamic data, int code) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return switch (code) {
      401 => '다시 로그인해 주세요',
      403 => '권한이 없어요',
      404 => '찾을 수 없어요',
      _ => '잠시 후 다시 시도해 주세요',
    };
  }
}
