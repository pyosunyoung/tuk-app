import 'dart:convert';

/// JWT payload 의 exp(만료 시각)를 읽는다. 서명은 검증하지 않는다 —
/// "곧 만료되니 미리 갱신하자"는 판단용일 뿐, 신뢰 판단은 서버가 한다.
/// 형식이 깨졌거나 exp 가 없으면 null.
DateTime? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(payload);
    final exp = json is Map ? json['exp'] : null;
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

/// [skew] 안에 만료되면(또는 exp 를 못 읽으면) 만료로 본다.
/// 연결 직후 만료돼 거부당하지 않도록 여유를 둔다.
bool jwtExpiresSoon(String token, {Duration skew = const Duration(seconds: 60), DateTime? now}) {
  final exp = jwtExpiry(token);
  if (exp == null) return true;
  return !exp.isAfter((now ?? DateTime.now().toUtc()).add(skew));
}
