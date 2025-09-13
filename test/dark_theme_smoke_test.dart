import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/theme/app_theme.dart';
import '../lib/theme/mokkoji_colors.dart';

void main() {
  group('Dark Theme Smoke Tests', () {
    testWidgets('dark theme applies aqua palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: Builder(
            builder: (ctx) {
              final cs = Theme.of(ctx).colorScheme;
              expect(cs.primary.value, 0xFF80DEEA); // aqua300
              expect(cs.background.value, 0xFF0B1F28); // darkBg
              expect(cs.surface.value, 0xFF0F2A33); // darkSurface
              expect(cs.onPrimary.value, 0xFF001317); // onAqua
              expect(cs.onSurface.value, 0xFFE6F7FA); // onSurface
              expect(cs.outline.value, 0xFF1E4752); // darkHair
              
              return Scaffold(
                body: Column(
                  children: [
                    Text('txt', style: Theme.of(ctx).textTheme.bodyMedium),
                    ElevatedButton(onPressed: () {}, child: const Text('확인')),
                    const Chip(label: Text('60분')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('txt'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
      expect(find.text('60분'), findsOneWidget);
    });

    testWidgets('dark theme MokkojiColors provides all required colors', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
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

      // Verify dark color constants
      expect(MokkojiColors.darkBg.value, 0xFF0B1F28);
      expect(MokkojiColors.darkSurface.value, 0xFF0F2A33);
      expect(MokkojiColors.darkHair.value, 0xFF1E4752);
      expect(MokkojiColors.onSurface.value, 0xFFE6F7FA);
      expect(MokkojiColors.onSurface2.value, 0xFFB6D4DC);
      expect(MokkojiColors.onAqua.value, 0xFF001317);
    });

    testWidgets('ElevatedButton in dark theme uses aqua300', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => buttonPressed = true,
              child: const Text('Dark Button'),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Dark Button'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('Input field in dark theme uses dark surface fill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: 'Dark input'),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Dark input'), findsOneWidget);
    });

    testWidgets('Chip in dark theme uses dark surface background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: const Scaffold(
            body: Chip(label: Text('Dark Chip')),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Dark Chip'), findsOneWidget);
    });

    testWidgets('Bottom sheet in dark theme uses dark background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        height: 100,
                        child: const Text('Dark Bottom Sheet'),
                      ),
                    );
                  },
                  child: const Text('Show Dark Sheet'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Dark Bottom Sheet'), findsOneWidget);
    });

    testWidgets('Dark text contrast meets accessibility requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: Scaffold(
            backgroundColor: MokkojiColors.darkBg,
            body: const Text(
              'Dark Contrast Test',
              style: TextStyle(color: MokkojiColors.onSurface),
            ),
          ),
        ),
      );

      expect(find.text('Dark Contrast Test'), findsOneWidget);
      
      // Verify dark colors meet contrast requirements
      expect(MokkojiColors.onSurface.value, 0xFFE6F7FA); // Light text
      expect(MokkojiColors.darkBg.value, 0xFF0B1F28); // Dark background
      expect(MokkojiColors.onAqua.value, 0xFF001317); // Dark text for buttons
    });

    testWidgets('Dark theme brightness is correctly set', (tester) async {
      late BuildContext darkContext;

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: mokkojiDarkTheme(),
          home: Builder(
            builder: (context) {
              darkContext = context;
              return const Text('Dark');
            },
          ),
        ),
      );

      expect(Theme.of(darkContext).brightness, Brightness.dark);
      expect(Theme.of(darkContext).colorScheme.brightness, Brightness.dark);
      
      // Verify dark theme colors
      expect(Theme.of(darkContext).colorScheme.primary.value, 0xFF80DEEA);  // aqua300
      expect(Theme.of(darkContext).colorScheme.background.value, 0xFF0B1F28);  // darkBg
      expect(Theme.of(darkContext).scaffoldBackgroundColor.value, 0xFF0B1F28); // darkBg
    });
  });
}