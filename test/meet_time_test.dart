import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/views/meet_time_sheet.dart';

/// 약속 시간 후보와 표시 문구.
///
/// 서버는 과거 1시간 ~ 미래 24시간만 받는다. 고를 수 있는 건 전부 저장도 돼야 하므로
/// 후보가 그 범위를 넘지 않는지 함께 본다.
void main() {
  group('후보 만들기', () {
    test('다음 30분 경계부터 시작한다', () {
      expect(meetTimeOptions(DateTime(2026, 9, 24, 19, 12)).first,
          DateTime(2026, 9, 24, 19, 30));
      expect(meetTimeOptions(DateTime(2026, 9, 24, 19, 47)).first,
          DateTime(2026, 9, 24, 20, 0));
      // 정각·30분 정각에도 과거가 나오면 안 된다
      expect(meetTimeOptions(DateTime(2026, 9, 24, 19, 0)).first,
          DateTime(2026, 9, 24, 19, 30));
      expect(meetTimeOptions(DateTime(2026, 9, 24, 19, 30)).first,
          DateTime(2026, 9, 24, 20, 0));
    });

    test('모든 후보가 미래이고 24시간을 넘지 않는다', () {
      final now = DateTime(2026, 9, 24, 23, 41);
      final options = meetTimeOptions(now);
      for (final o in options) {
        expect(o.isAfter(now), isTrue, reason: '$o');
        expect(o.difference(now).inHours, lessThan(24), reason: '$o');
      }
    });

    test('자정을 넘어가도 이어진다', () {
      final options = meetTimeOptions(DateTime(2026, 9, 24, 23, 10));
      expect(options[0], DateTime(2026, 9, 24, 23, 30));
      expect(options[1], DateTime(2026, 9, 25, 0, 0));
    });
  });

  group('표시 문구', () {
    final today = DateTime(2026, 9, 24, 19, 0);

    test('오전·오후와 12시 처리', () {
      expect(meetTimeLabel(DateTime(2026, 9, 24, 20, 0), now: today), '오늘 오후 8시');
      expect(meetTimeLabel(DateTime(2026, 9, 24, 9, 0), now: today), '오늘 오전 9시');
      expect(meetTimeLabel(DateTime(2026, 9, 24, 12, 0), now: today), '오늘 오후 12시');
      expect(meetTimeLabel(DateTime(2026, 9, 24, 0, 30), now: today), '오늘 오전 12시 30분');
    });

    test('30분은 분까지, 정각은 생략', () {
      expect(meetTimeLabel(DateTime(2026, 9, 24, 20, 30), now: today), '오늘 오후 8시 30분');
      expect(meetTimeLabel(DateTime(2026, 9, 24, 20, 0), now: today), isNot(contains('분')));
    });

    test('날짜가 넘어가면 내일', () {
      expect(meetTimeLabel(DateTime(2026, 9, 25, 1, 0), now: today), startsWith('내일'));
    });
  });
}
