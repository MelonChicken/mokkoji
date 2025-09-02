// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mokkoji_app/main.dart';

void main() {
  testWidgets('Mokkoji app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MokkojiApp());

    // Verify that our app renders correctly
    expect(find.text('모꼬지'), findsAtLeastNWidgets(1));
    expect(find.text('첫 일정 09:30, 총 4건 · 강남역까지 23분'), findsOneWidget);

    // Verify navigation buttons are present
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    
    // Verify floating action button
    expect(find.text('모으기'), findsOneWidget);
  });
}
