import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/services/api_client.dart';
import 'package:tuk/services/token_storage.dart';

/// 서버처럼 refresh 를 회전(rotation)시키는 가짜.
/// 이미 바뀐 옛 refresh 가 다시 오면 서버와 똑같이 401(재사용 탐지)로 답한다 —
/// 그래서 앱이 refresh 를 하나로 합치지 못하면 이 테스트에서 세션이 끊긴다.
class FakeServer implements HttpClientAdapter {
  FakeServer({required this.validAccess, required this.validRefresh});

  String validAccess;
  String validRefresh;
  int refreshCalls = 0;
  int? refreshStatus; // 지정하면 refresh 가 이 상태로 실패
  final List<String?> apiAuthHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      // 네트워크 왕복 동안 다른 요청이 끼어들 틈을 준다
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refreshStatus != null) return _json(refreshStatus!, {'message': 'x'});
      final presented = (options.data as Map)['refreshToken'];
      if (presented != validRefresh) return _json(401, {'message': '재사용'});
      validAccess = jwtExpiringIn(const Duration(minutes: 30), 'a$refreshCalls');
      validRefresh = 'r$refreshCalls';
      return _json(200, {'accessToken': validAccess, 'refreshToken': validRefresh});
    }

    final auth = options.headers['Authorization'] as String?;
    apiAuthHeaders.add(auth);
    if (auth != 'Bearer $validAccess') return _json(401, {'message': '만료'});
    return _json(200, {'path': options.path});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// 메모리에만 두는 토큰 저장소(보안 저장소 플러그인 없이).
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage(this._access, this._refresh);

  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;
  @override
  String? get refreshToken => _refresh;
  @override
  bool get hasSession => _refresh != null;
  @override
  Future<void> load() async {}
  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

String jwtExpiringIn(Duration d, String id) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final exp = DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;
  return '${seg({'alg': 'HS512'})}.${seg({'sub': '1', 'jti': id, 'exp': exp})}.c2ln';
}

void main() {
  late FakeServer server;
  late MemoryTokenStorage tokens;
  late ApiClient api;
  late int sessionExpired;

  setUp(() {
    // 앱을 오래 안 쓰다 켠 상황: access 는 만료, refresh 는 유효
    final expired = jwtExpiringIn(const Duration(minutes: -5), 'a0');
    server = FakeServer(validAccess: 'a-not-issued-yet', validRefresh: 'r0');
    tokens = MemoryTokenStorage(expired, 'r0');
    sessionExpired = 0;
    api = ApiClient(
      tokens,
      onSessionExpired: () async => sessionExpired++,
      adapter: server,
    );
  });

  test('동시에 401 이 3개 나도 refresh 는 한 번, 세 요청 모두 새 토큰으로 재시도해 성공', () async {
    final results = await Future.wait(<Future<dynamic>>[
      api.get('/api/flashes/received'),
      api.get('/api/presence/friends'),
      api.get('/api/friendships'),
    ]);

    expect(server.refreshCalls, 1);
    expect(sessionExpired, 0);
    expect(results, hasLength(3));
    expect(tokens.refreshToken, 'r1');
    // 첫 시도 3번(만료 토큰) + 재시도 3번(새 토큰)
    expect(server.apiAuthHeaders.where((h) => h == 'Bearer ${server.validAccess}'), hasLength(3));
  });

  test('실시간 연결(STOMP)용 토큰 요청이 HTTP 401 과 겹쳐도 refresh 는 한 번', () async {
    final results = await Future.wait(<Future<dynamic>>[
      api.validAccessToken(), // 만료된 토큰이라 연결 전에 갱신
      api.get('/api/flashes/received'),
    ]);

    expect(server.refreshCalls, 1);
    expect(sessionExpired, 0);
    expect(results.first, server.validAccess);
  });

  test('refresh 가 401 이면 세션 만료 처리(좀비 세션 방지)', () async {
    server.refreshStatus = 401;

    await expectLater(api.get('/api/friendships'), throwsA(isA<ApiException>()));
    expect(sessionExpired, 1);
  });

  test('refresh 가 5xx 면 서버 사정이므로 세션은 유지', () async {
    server.refreshStatus = 503;

    await expectLater(api.get('/api/friendships'), throwsA(isA<ApiException>()));
    expect(sessionExpired, 0);
    expect(tokens.refreshToken, 'r0');
  });

  test('refresh 가 끝나면 다음 만료 때 다시 refresh 할 수 있다(합친 상태가 남지 않음)', () async {
    await api.get('/api/friendships');
    expect(server.refreshCalls, 1);

    server.validAccess = 'rotated-on-server'; // 앱이 가진 access 가 다시 무효가 됨
    await api.get('/api/friendships');

    expect(server.refreshCalls, 2);
    expect(sessionExpired, 0);
  });
}
