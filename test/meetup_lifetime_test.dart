import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/models/activity.dart';
import 'package:tuk/models/flash.dart';

/// 홈에서 모임이 언제까지 보이는가.
///
/// 약속 시간이 잡힌 모임은 합류 마감이 지나도 남아야 한다 — "어디서 몇 시더라"를
/// 다시 보려고 만든 기능이다. 서버는 그렇게 내려주는데 앱의 1분 타이머가
/// 합류 마감만 보고 지워서, 약속을 잡아둔 모임이 조용히 사라진 적이 있다.
void main() {
  final now = DateTime(2026, 9, 24, 22, 45);

  SentFlash sent({DateTime? expiresAt, DateTime? meetAt}) => SentFlash(
        flashId: 1,
        activity: Activity.meal,
        expiresAt: expiresAt,
        meetAt: meetAt,
        joined: const [],
      );

  /// 뷰모델의 _tick 과 같은 판정.
  bool alive(SentFlash f) {
    final a = f.expiresAt, b = f.meetAt;
    final until = a == null ? b : (b == null ? a : (a.isAfter(b) ? a : b));
    return until == null || until.isAfter(now);
  }

  test('합류 마감이 지나도 약속 시간이 남았으면 남는다', () {
    final f = sent(
      expiresAt: now.subtract(const Duration(minutes: 25)), // 마감 지남
      meetAt: now.add(const Duration(hours: 2)),            // 약속은 남음
    );
    expect(alive(f), isTrue);
  });

  test('약속을 안 잡았으면 마감과 함께 사라진다', () {
    expect(alive(sent(expiresAt: now.subtract(const Duration(minutes: 1)))), isFalse);
    expect(alive(sent(expiresAt: now.add(const Duration(minutes: 1)))), isTrue);
  });

  test('약속 시간도 지나면 사라진다', () {
    final f = sent(
      expiresAt: now.subtract(const Duration(hours: 3)),
      meetAt: now.subtract(const Duration(minutes: 1)),
    );
    expect(alive(f), isFalse);
  });

  test('meetAt 파싱 — 서버가 주는 두 시각이 섞이지 않는다', () {
    final f = SentFlash.fromJson({
      'flashId': 7,
      'activity': 'WALK',
      'expiresAt': '2026-09-24T22:20:00',
      'meetAt': '2026-09-25T01:19:00',
      'joinedMembers': [],
    });
    expect(f.expiresAt, DateTime(2026, 9, 24, 22, 20));
    expect(f.meetAt, DateTime(2026, 9, 25, 1, 19));
  });
}
