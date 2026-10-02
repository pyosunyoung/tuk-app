import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/keep_words.dart';

void main() {
  test('띄어쓰기·줄바꿈은 그대로, 그 사이 글자들에만 줄 나눔 금지 표시', () {
    expect(keepWords('보낸 사람'), '보⁠낸 사⁠람');
    expect(keepWords('끝나요.\n모인'), '끝⁠나⁠요⁠.\n모⁠인');
  });

  test('표시를 지우면 원문과 같다(화면에 보이는 글자는 그대로)', () {
    const text = '한가하다는 표시도, 툭에 합류 받는 것도 시간이 지나면 끝나요.';
    expect(keepWords(text).replaceAll('⁠', ''), text);
  });

  test('한글이 없으면 그대로 둔다', () {
    expect(keepWords('ABC-123'), 'ABC-123');
  });

  test('이모지 옆에는 끼우지 않는다(조합 이모지가 깨지지 않게)', () {
    expect(keepWords('👍🏻좋아'), '👍🏻좋⁠아');
    expect(keepWords('🎮 PC방'), '🎮 PC⁠방');
  });
}
