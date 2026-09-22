import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/models/meetup_room.dart';

/// 공유 카드 링크로 모임방에 바로 들어오면 앞선 목록 응답을 못 받는다.
/// 그때 남은 시간을 보여줄 수 있도록 방 응답이 만료 시각을 함께 준다.
void main() {
  Map<String, dynamic> json({Object? expiresAt = '2026-09-22T21:30:00'}) => {
        'roomId': 20,
        'flashId': 85,
        'activity': 'MEAL',
        'status': 'OPEN',
        'expiresAt': expiresAt,
        'members': [
          {'userId': 1, 'nickname': '보낸이', 'sender': true},
        ],
      };

  test('방 응답의 만료 시각을 읽는다', () {
    final room = MeetupRoom.fromJson(json());
    expect(room.expiresAt, DateTime(2026, 9, 22, 21, 30));
  });

  test('만료 시각이 없거나 이상해도 방은 열린다', () {
    expect(MeetupRoom.fromJson(json(expiresAt: null)).expiresAt, isNull);
    expect(MeetupRoom.fromJson(json(expiresAt: '이상한값')).expiresAt, isNull);
  });
}
