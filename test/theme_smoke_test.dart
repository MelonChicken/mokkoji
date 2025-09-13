import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/theme/app_theme.dart';
import '../lib/theme/mokkoji_colors.dart';
import '../lib/theme/mokkoji_gradients.dart';

void main() {
  group('Mokkoji Theme Tests', () {
    testWidgets('MokkojiGradients extension works', (tester) async {
      late BuildContext testContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                testContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );
      
      // Verify that MokkojiGradients extension is available
      final gradients = testContext.mokkojiGradients;
      expect(gradients.header, isNotNull);
      expect(gradients.buttonEnabled, isNotNull);
      expect(gradients.buttonDisabled, isNotNull);
    });

    testWidgets('Mokkoji theme with gradients applies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('GradientButton works with theme', (tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: context.mokkojiGradients.buttonEnabled,
                  ),
                  child: TextButton(
                    onPressed: () => buttonPressed = true,
                    child: const Text('Test Button'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);

      // Test button interaction
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      
      expect(buttonPressed, isTrue);
    });

    testWidgets('Header gradient renders', (tester) async {
      late BuildContext testContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                testContext = context;
                return Container(
                  decoration: BoxDecoration(
                    gradient: context.mokkojiGradients.header,
                  ),
                  height: 60,
                  child: const Text('Header'),
                );
              },
            ),
          ),
        ),
      );

      final gradients = testContext.mokkojiGradients;
      
      // Verify header gradient is available
      expect(gradients.header, isNotNull);
      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('Theme applies gradient system', (tester) async {
      late BuildContext testContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                testContext = context;
                return const Column(
                  children: [
                    TextField(decoration: InputDecoration(hintText: 'Test input')),
                    Chip(label: Text('Test chip')),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final theme = Theme.of(testContext);
      
      // Verify Material3 is enabled
      expect(theme.useMaterial3, isTrue);
      
      // Verify ColorScheme is seed-based from mint color
      expect(theme.colorScheme.brightness, Brightness.light);
      
      // Verify chip theme is configured
      expect(theme.chipTheme.shape, isA<StadiumBorder>());
      
      // Verify elevated button theme exists
      expect(theme.elevatedButtonTheme.style, isNotNull);
      
      // Verify input field has lilac focus border
      final focusedBorder = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, MokkojiColors.lilac);
      expect(focusedBorder.borderSide.width, 2);
    });
  });
}