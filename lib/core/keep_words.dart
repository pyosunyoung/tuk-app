/// 한글이 단어 중간에서 줄바꿈되지 않게 한다("보낸 사/람에겐" → "보낸 / 사람에겐").
///
/// Flutter 는 한글을 글자마다 줄을 나눌 수 있는 곳으로 본다(CSS 의 word-break: keep-all 이 없다).
/// 그래서 띄어쓰기가 아닌 글자 사이에 "줄 나누지 말 것" 표시(U+2060 WORD JOINER)를 끼워,
/// 띄어쓰기와 줄바꿈에서만 넘어가게 한다. 화면에는 보이지 않는다.
///
/// 앱의 모든 Text 에 적용돼 있다(새 Text 를 만들 때도 keepWords 로 감싼다).
/// 한글이 낀 자리에만 끼우고, 이모지 옆에는 끼우지 않는다(👍🏻 같은 조합 이모지가 깨진다).
/// 한 단어가 한 줄보다 길면 그 단어는 넘친 채로 잘리지 않고 글자 단위로 다시 나뉜다(Flutter 기본 동작).
String keepWords(String text) {
  final chars = text.runes.toList();
  if (!chars.any(_isHangul)) return text;
  final buffer = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    buffer.writeCharCode(chars[i]);
    if (i + 1 < chars.length && _shouldJoin(chars[i], chars[i + 1])) {
      buffer.write('⁠');
    }
  }
  return buffer.toString();
}

bool _shouldJoin(int a, int b) {
  if (_isBreak(a) || _isBreak(b) || _isEmojiPart(a) || _isEmojiPart(b)) return false;
  return _isHangul(a) || _isHangul(b);
}

bool _isBreak(int rune) => rune == 0x20 || rune == 0x0A;

bool _isHangul(int rune) =>
    (rune >= 0xAC00 && rune <= 0xD7A3) || // 완성형
    (rune >= 0x1100 && rune <= 0x11FF) || // 자모
    (rune >= 0x3130 && rune <= 0x318F); // 호환 자모(ㅋㅋ)

bool _isEmojiPart(int rune) =>
    rune >= 0x1F000 ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    rune == 0x200D || // ZWJ
    (rune >= 0xFE00 && rune <= 0xFE0F); // 변형 선택자
