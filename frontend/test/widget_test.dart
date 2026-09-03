import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globetrotter_frontend/main.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const GlobeTrotterApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));


    expect(find.text('GlobeTrotter'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });
}
