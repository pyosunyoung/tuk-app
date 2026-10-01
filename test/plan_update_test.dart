import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/models/realtime_event.dart';
import 'package:tuk/views/room_screen.dart';

void main() {
  FlashPushEvent parse(Map<String, dynamic> json) =>
      FlashPushEvent.fromJson({'flashId': 10, 'userId': 1, 'nickname': '민수', ...json});

  group('장소·시간 정함/바꿈 이벤트', () {
    test('PLACE_UPDATED: 이전 값이 없으면 정함, 있으면 바꿈', () {
      final first = parse({'type': 'PLACE_UPDATED', 'placeAfter': '홍대입구역'});
      expect(first.isPlanUpdated, isTrue);
      expect(planUpdateText(first), '민수님이 장소를 정했어요 · 홍대입구역');

      final change = parse({'type': 'PLACE_UPDATED', 'placeBefore': '홍대입구역', 'placeAfter': '합정역'});
      expect(planUpdateText(change), '민수님이 장소를 바꿨어요 · 합정역');
    });

    test('MEET_AT_UPDATED: 시간을 앱 표기(meetTimeLabel)로 보여준다', () {
      final at = DateTime.now().add(const Duration(hours: 1));
      final wire = DateTime(at.year, at.month, at.day, at.hour).toIso8601String();

      final first = parse({'type': 'MEET_AT_UPDATED', 'meetAtAfter': wire});
      expect(first.meetAtAfter, isNotNull);
      expect(planUpdateText(first), startsWith('민수님이 시간을 정했어요 · '));

      final change = parse({'type': 'MEET_AT_UPDATED', 'meetAtBefore': wire, 'meetAtAfter': wire});
      expect(planUpdateText(change), startsWith('민수님이 시간을 바꿨어요 · '));
    });

    test('방 밖 토스트는 어느 모임인지 앞에 붙인다', () {
      final e = parse({'type': 'PLACE_UPDATED', 'activity': 'MEAL', 'placeBefore': '홍대입구역', 'placeAfter': '합정역'});
      expect(planUpdateText(e, withActivity: true), '밥 · 민수님이 장소를 바꿨어요 · 합정역');
      expect(planUpdateText(e), '민수님이 장소를 바꿨어요 · 합정역');

      final joined = parse({'type': 'MEMBER_JOINED', 'activity': 'CAFE'});
      expect(memberJoinedText(joined), '카페 · 민수님이 합류했어요');
      expect(memberJoinedText(parse({'type': 'MEMBER_JOINED'})), '민수님이 합류했어요');
    });

    test('합류·새 툭은 장소·시간 이벤트가 아니다', () {
      expect(parse({'type': 'MEMBER_JOINED'}).isPlanUpdated, isFalse);
      expect(parse({'type': 'NEW_FLASH'}).isPlanUpdated, isFalse);
    });
  });
}
