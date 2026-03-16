import 'package:flutter_test/flutter_test.dart';

import 'package:css_to_flutter/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CssToFlutterApp());
    expect(find.text('CSS to Flutter'), findsOneWidget);
  });
}
