/// 한글이 단어 중간에서 줄바꿈되지 않게 한다("보낸 사/람에겐" → "보낸 / 사람에겐").
///
/// Flutter 는 한글을 글자마다 줄을 나눌 수 있는 곳으로 본다(CSS 의 word-break: keep-all 이 없다).
/// 그래서 띄어쓰기가 아닌 글자 사이에 "줄 나누지 말 것" 표시(U+2060 WORD JOINER)를 끼워,
/// 띄어쓰기와 줄바꿈에서만 넘어가게 한다. 화면에는 보이지 않는다.
///
/// 한 단어가 한 줄보다 길면 그 단어는 넘친 채로 잘리지 않고 글자 단위로 다시 나뉜다(Flutter 기본 동작).
String keepWords(String text) {
  final buffer = StringBuffer();
  final chars = text.runes.toList();
  for (var i = 0; i < chars.length; i++) {
    buffer.writeCharCode(chars[i]);
    if (i + 1 < chars.length && !_isBreak(chars[i]) && !_isBreak(chars[i + 1])) {
      buffer.write('⁠');
    }
  }
  return buffer.toString();
}

bool _isBreak(int rune) => rune == 0x20 || rune == 0x0A;
