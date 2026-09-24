import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/services/api_client.dart';

/// 서버에 닿지 못했을 때 화면에 무엇을 말하는가.
///
/// 로그인 화면은 한동안 "서버가 켜져 있는지 확인해주세요" 를 띄우고 있었다.
/// 개발자에게 하던 말이 제품에 그대로 남은 것으로, 사용자는 서버가 뭔지도
/// 어떻게 확인하는지도 모른다. 그런 문구가 다시 새어드는 걸 여기서 막는다.
void main() {
  final everyType = DioExceptionType.values;

  test('연결이 안 되면 인터넷 확인을 안내한다', () {
    expect(
      connectionMessageFor(DioExceptionType.connectionError),
      contains('인터넷'),
    );
  });

  test('응답이 늦으면 다시 시도를 안내한다', () {
    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(connectionMessageFor(t), contains('잠시 후'), reason: '$t');
    }
  });

  test('어떤 경우에도 내부 사정을 드러내지 않는다', () {
    for (final t in everyType) {
      final msg = connectionMessageFor(t);
      expect(msg, isNotEmpty, reason: '$t');
      // 사용자가 손댈 수 없는 것들 — 서버 상태, 예외 이름, 상태 코드
      expect(msg, isNot(contains('서버')), reason: '$t');
      expect(msg, isNot(contains('Dio')), reason: '$t');
      expect(msg, isNot(matches(RegExp(r'\d{3}'))), reason: '$t');
    }
  });

  test('말투는 앱과 같은 해요체', () {
    for (final t in everyType) {
      expect(connectionMessageFor(t), endsWith('세요'), reason: '$t');
    }
  });
}
