import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/flash_format.dart';

/// 합류 마감 임박 판정.
///
/// 문구("곧 끝나요")가 바뀌는 시점과 테두리 강조 시점이 어긋나면
/// "곧 끝나요"인데 평범해 보이거나 그 반대가 된다 — 같은 기준을 쓰는지 본다.
void main() {
  DateTime inMinutes(int m) => DateTime.now().add(Duration(minutes: m));

  test('10분 미만이면 임박', () {
    expect(flashEndingSoon(inMinutes(1)), isTrue);
    expect(flashEndingSoon(inMinutes(9)), isTrue);
  });

  test('10분 이상이면 임박 아님', () {
    expect(flashEndingSoon(inMinutes(11)), isFalse);
    expect(flashEndingSoon(inMinutes(120)), isFalse);
  });

  test('이미 지났으면 임박 아님 — 끝난 것은 강조할 게 없다', () {
    expect(flashEndingSoon(inMinutes(-1)), isFalse);
    expect(flashEndingSoon(inMinutes(-120)), isFalse);
  });

  test('문구와 같은 기준으로 바뀐다', () {
    // 임박이면 "곧 끝나요", 아니면 남은 시간을 말한다
    expect(flashExpiryText(inMinutes(5)), '곧 끝나요');
    expect(flashEndingSoon(inMinutes(5)), isTrue);

    expect(flashExpiryText(inMinutes(30)), contains('분 뒤'));
    expect(flashEndingSoon(inMinutes(30)), isFalse);
  });
}
