// Simple test to verify event creation works
import 'package:flutter/foundation.dart';
import 'lib/data/repositories/event_repository.dart';

void main() async {
  if (kDebugMode) {
    print('Testing event creation...');
    
    try {
      final request = EventCreateRequest(
        id: 'test-event-1',
        title: '테스트 이벤트',
        description: '이것은 테스트용 이벤트입니다',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        location: '테스트 장소',
      );
      
      await eventRepository.createEvent(request);
      print('✅ Event created successfully!');
      
      // Try to retrieve it
      final event = await eventRepository.getById('test-event-1');
      if (event != null) {
        print('✅ Event retrieved successfully: ${event.title}');
      } else {
        print('❌ Event not found after creation');
      }
      
    } catch (e) {
      print('❌ Error creating event: $e');
    }
  }
}