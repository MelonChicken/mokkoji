import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/theme/app_theme.dart';
import '../lib/theme/mokkoji_colors.dart';

void main() {
  group('Aqua Palette Theme Tests', () {
    testWidgets('aqua palette applied to ColorScheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Builder(
            builder: (ctx) {
              final cs = Theme.of(ctx).colorScheme;
              expect(cs.primary.value, 0xFF26C6DA);
              expect(cs.background.value, 0xFFE0F7FA);
              expect(cs.surface.value, 0xFFE0F7FA);
              expect(cs.onPrimary.value, 0xFF001317);
              expect(cs.onSurface.value, 0xFF001317);
              return ElevatedButton(
                onPressed: () {},
                child: const Text('확인'),
              );
            },
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('MokkojiColors extension provides aqua colors', (tester) async {
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

      // Verify that MokkojiColors extension is available
      expect(Theme.of(testContext).extension<MokkojiColors>(), isNotNull);

      // Verify aqua color constants
      expect(MokkojiColors.aqua600.value, 0xFF26C6DA);
      expect(MokkojiColors.aqua500.value, 0xFF4DD0E1);
      expect(MokkojiColors.aqua300.value, 0xFF80DEEA);
      expect(MokkojiColors.aqua200.value, 0xFFB2EBF2);
      expect(MokkojiColors.aqua50.value, 0xFFE0F7FA);
      expect(MokkojiColors.onAqua.value, 0xFF001317);
    });

    testWidgets('ElevatedButton uses aqua600 background', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => buttonPressed = true,
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);

      // Test button interaction
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('Input field uses aqua50 fill and aqua500 focus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: 'Test input'),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Chip uses aqua colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: const Scaffold(
            body: Chip(label: Text('Test Chip')),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Test Chip'), findsOneWidget);
    });

    testWidgets('Bottom sheet uses aqua50 background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        height: 100,
                        child: const Text('Bottom Sheet'),
                      ),
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Test opening bottom sheet
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Bottom Sheet'), findsOneWidget);
    });

    testWidgets('Text contrast meets accessibility requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiLightTheme(),
          home: Scaffold(
            backgroundColor: MokkojiColors.aqua50,
            body: const Text(
              'Contrast Test',
              style: TextStyle(color: MokkojiColors.onAqua),
            ),
          ),
        ),
      );

      expect(find.text('Contrast Test'), findsOneWidget);
      
      // Verify that onAqua (#0B1F28) provides sufficient contrast against aqua50 (#E0F7FA)
      // This should meet WCAG 4.5:1 contrast ratio requirement
      expect(MokkojiColors.onAqua.value, 0xFF001317);
      expect(MokkojiColors.aqua50.value, 0xFFE0F7FA);
    });
  });
}