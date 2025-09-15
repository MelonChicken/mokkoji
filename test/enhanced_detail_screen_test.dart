import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/screens/enhanced_detail_screen.dart';

void main() {
  group('EnhancedDetailScreen', () {
    testWidgets('Should display enhanced detail screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const EnhancedDetailScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // Should show the screen structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Should show edit button in view mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const EnhancedDetailScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // Should show edit button in AppBar
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}