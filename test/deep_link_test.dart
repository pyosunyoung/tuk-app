import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/deep_link.dart';

void main() {
  Uri kakao(String query) => Uri.parse('kakaoe0a9fa462f80243f11b982ca83b15bf8://kakaolink?$query');

  test('모임방 카드', () {
    expect(TukLink.parse(kakao('room=123')), const RoomLink(123));
  });

  test('초대 카드 — 소문자·공백도 코드로 정리', () {
    expect(TukLink.parse(kakao('invite=HJFT846T')), const InviteLink('HJFT846T'));
    expect(TukLink.parse(kakao('invite=%20hjft846t%20')), const InviteLink('HJFT846T'));
  });

  test('모르는 값·위험한 값은 무시한다', () {
    expect(TukLink.parse(kakao('')), isNull);
    expect(TukLink.parse(kakao('room=abc')), isNull);
    expect(TukLink.parse(kakao('room=-1')), isNull);
    expect(TukLink.parse(kakao('invite=AB')), isNull); // 너무 짧음
    expect(TukLink.parse(kakao('invite=AB%3BDROP')), isNull); // 영숫자 아님
    expect(TukLink.parse(kakao('foo=bar')), isNull);
  });
}
