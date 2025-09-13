import 'package:flutter_test/flutter_test.dart';
import '../lib/db/db_signal.dart';

void main() {
  group('DbSignal Stream Tests', () {
    test('should emit when pingEvents is called', () async {
      // Listen to the events stream
      final streamEvents = <void>[];
      final subscription = DbSignal.instance.eventsStream.listen((event) {
        streamEvents.add(event);
      });

      // Initially should have no events
      expect(streamEvents, isEmpty);

      // Ping events
      DbSignal.instance.pingEvents();

      // Wait a bit for stream to emit
      await Future.delayed(const Duration(milliseconds: 10));

      // Should have received one event
      expect(streamEvents.length, equals(1));

      // Ping again
      DbSignal.instance.pingEvents();
      await Future.delayed(const Duration(milliseconds: 10));

      // Should have received two events
      expect(streamEvents.length, equals(2));

      // Cleanup
      await subscription.cancel();
    });

    test('should handle multiple subscribers', () async {
      final subscriber1Events = <void>[];
      final subscriber2Events = <void>[];

      final sub1 = DbSignal.instance.eventsStream.listen((event) {
        subscriber1Events.add(event);
      });

      final sub2 = DbSignal.instance.eventsStream.listen((event) {
        subscriber2Events.add(event);
      });

      // Ping events
      DbSignal.instance.pingEvents();
      await Future.delayed(const Duration(milliseconds: 10));

      // Both should receive the event
      expect(subscriber1Events.length, equals(1));
      expect(subscriber2Events.length, equals(1));

      // Cleanup
      await sub1.cancel();
      await sub2.cancel();
    });
  });
}