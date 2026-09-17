import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/jwt.dart';

/// 서명은 검사하지 않으니 가짜 서명으로 충분하다.
String fakeJwt(Map<String, dynamic> payload) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({'alg': 'HS512'})}.${seg(payload)}.c2lnbmF0dXJl';
}

void main() {
  final now = DateTime.utc(2026, 9, 17, 12, 0, 0);
  int epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

  test('exp 를 UTC 시각으로 읽는다', () {
    final token = fakeJwt({'sub': '1', 'exp': epoch(now)});
    expect(jwtExpiry(token), now);
  });

  test('base64 패딩이 없는 payload 도 읽는다 (JWT 는 패딩을 뺀다)', () {
    // 길이가 4의 배수가 아닌 payload 가 나오도록 sub 길이를 조절
    for (final sub in ['1', '12', '123', '1234']) {
      final token = fakeJwt({'sub': sub, 'exp': epoch(now)});
      expect(jwtExpiry(token), now, reason: 'sub=$sub');
    }
  });

  group('jwtExpiresSoon (기본 여유 60초)', () {
    test('30분 남음 → 유효', () {
      final token = fakeJwt({'exp': epoch(now.add(const Duration(minutes: 30)))});
      expect(jwtExpiresSoon(token, now: now), isFalse);
    });

    test('이미 만료 → 갱신 필요', () {
      final token = fakeJwt({'exp': epoch(now.subtract(const Duration(minutes: 5)))});
      expect(jwtExpiresSoon(token, now: now), isTrue);
    });

    test('30초 남음 → 연결 중 만료될 수 있으니 갱신 필요', () {
      final token = fakeJwt({'exp': epoch(now.add(const Duration(seconds: 30)))});
      expect(jwtExpiresSoon(token, now: now), isTrue);
    });

    test('형식이 깨졌거나 exp 가 없으면 안전하게 갱신 쪽으로', () {
      expect(jwtExpiresSoon('not-a-jwt', now: now), isTrue);
      expect(jwtExpiresSoon('a.b.c', now: now), isTrue);
      expect(jwtExpiresSoon(fakeJwt({'sub': '1'}), now: now), isTrue);
    });
  });
}
