import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/services/update_checker.dart';

void main() {
  const info = AppVersionInfo(latestVersion: '1.0.2', latestBuild: 3, minBuild: 2);

  test('최신이면 안내하지 않는다', () {
    expect(UpdateChecker.decide(info, 3, null), isNull);
  });

  test('새 버전이 있으면 한 번만 안내한다(재촉하지 않음)', () {
    expect(UpdateChecker.decide(info, 2, null)?.required, isFalse);
    expect(UpdateChecker.decide(info, 2, 3), isNull); // 이미 본 버전
  });

  test('너무 오래된 버전이면 봤어도 매번 안내한다', () {
    expect(UpdateChecker.decide(info, 1, 3)?.required, isTrue);
  });
}
