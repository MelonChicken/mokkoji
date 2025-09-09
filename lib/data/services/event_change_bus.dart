import 'dart:async';

/// Event change notification data
class EventChanged {
  final String eventId;
  final EventChangeType type;
  final DateTime timestamp;
  
  EventChanged({
    required this.eventId,
    required this.type,
    required this.timestamp,
  });
}

enum EventChangeType {
  created,
  updated,
  deleted,
}

/// Centralized event change bus for notifying all subscribers
/// about database changes that affect event streams
class EventChangeBus {
  static final EventChangeBus _instance = EventChangeBus._();
  static EventChangeBus get instance => _instance;
  
  EventChangeBus._();
  
  final _controller = StreamController<EventChanged>.broadcast();
  
  /// Stream of event changes
  Stream<EventChanged> get stream => _controller.stream;
  
  /// Emit an event change
  void emit(EventChanged change) {
    _controller.add(change);
  }
  
  /// Emit multiple changes
  void emitAll(List<EventChanged> changes) {
    for (final change in changes) {
      _controller.add(change);
    }
  }
  
  /// Close the bus
  void dispose() {
    _controller.close();
  }
}