import 'package:flutter_test/flutter_test.dart';

import 'package:bungae/main.dart';

void main() {
  testWidgets('앱이 뜨고 번개 플레이스홀더가 보인다', (tester) async {
    await tester.pumpWidget(const BungaeApp());
    expect(find.text('번개'), findsOneWidget);
  });
}
