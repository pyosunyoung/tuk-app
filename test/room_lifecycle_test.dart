import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/flash_format.dart';

/// 모임방의 세 단계.
///
/// 예전엔 "합류 마감 = 모임 종료" 로 한 덩어리였다. 그래서 7시 약속인데 6시에
/// 합류가 마감되면, 아직 만나지도 않은 모임이 6시부터 읽기 전용으로 박제됐다.
/// (비 와서 장소를 바꾸려 해도 앱에서 못 바꿨다 — 서버는 허용하는데도)
void main() {
  DateTime ago(int m) => DateTime.now().subtract(Duration(minutes: m));
  DateTime later(int m) => DateTime.now().add(Duration(minutes: m));

  /// room_screen 의 _joinClosed / _over 와 같은 판정.
  bool joinClosed(DateTime expiresAt) => flashEnded(expiresAt);
  bool over(DateTime expiresAt, DateTime? meetAt) =>
      meetAt != null ? flashEnded(meetAt) : flashEnded(expiresAt);

  test('① 모으는 중 — 둘 다 아니다', () {
    expect(joinClosed(later(30)), isFalse);
    expect(over(later(30), later(120)), isFalse);
  });

  test('② 합류 마감 — 새 사람만 못 들어온다. 모임은 살아 있다', () {
    final expires = ago(10);
    final meet = later(120);
    expect(joinClosed(expires), isTrue);
    expect(over(expires, meet), isFalse, reason: '약속 시간이 남았으면 끝난 게 아니다');
  });

  test('③ 모임 종료 — 약속 시간까지 지났다', () {
    expect(over(ago(180), ago(10)), isTrue);
  });

  test('약속을 안 정했으면 합류 마감이 곧 종료다', () {
    expect(over(ago(10), null), isTrue);
    expect(over(later(10), null), isFalse);
  });
}
