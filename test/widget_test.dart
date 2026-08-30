import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuk/core/theme.dart';
import 'package:tuk/widgets/logo.dart';

void main() {
  testWidgets('툭 로고가 테마 위에서 렌더된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: TukLogo(size: 80))),
      ),
    );
    expect(find.text('툭'), findsOneWidget);
  });
}
