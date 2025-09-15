import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to verify Korean IME composition preservation in TextFields
void main() {
  group('Korean IME TextFields', () {
    testWidgets('Should preserve composition during Korean input', (tester) async {
      late String capturedText;
      late TextEditingController controller;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              controller = TextEditingController();
              controller.addListener(() {
                capturedText = controller.text;
              });

              return TextField(
                controller: controller,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  letterSpacing: 0, // Korean character separation prevention
                ),
                textCapitalization: TextCapitalization.none,
                enableSuggestions: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(200), // Length limit only
                ],
              );
            },
          ),
        ),
      ));

      // Simulate typing Korean text
      const koreanText = '프로젝트 공유합니다ㅎㅎ';
      await tester.enterText(find.byType(TextField), koreanText);

      // Verify text was captured correctly without manipulation
      expect(capturedText, equals(koreanText));
      expect(controller.text, equals(koreanText));
    });

    testWidgets('Should not reset controller during composition', (tester) async {
      late TextEditingController controller;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              controller = TextEditingController(text: 'initial');

              return TextField(
                controller: controller,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  letterSpacing: 0,
                ),
                textCapitalization: TextCapitalization.none,
                enableSuggestions: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(200),
                ],
              );
            },
          ),
        ),
      ));

      // Check initial state
      expect(controller.text, equals('initial'));

      // Simulate partial Korean composition
      await tester.enterText(find.byType(TextField), 'initialㅎ');

      // Verify composition is preserved
      expect(controller.text, equals('initialㅎ'));
    });
  });
}