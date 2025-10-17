# Real-time Event Collection System

## Overview

This implementation provides a real-time event collection system with immediate UI updates using streams. The system handles timezone conversion, efficient upsert operations, and maintains data consistency across the application.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CollectService │───▶│    EventDao      │───▶│  EventRepository│
│   (Fetch events) │    │  (Store & Stream)│    │   (UI Streams)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                         │
                                ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │    DbSignal      │    │   BowlView      │
                       │  (Change Bus)    │    │  CalendarView   │
                       └──────────────────┘    └─────────────────┘
```

## Key Features

- **Real-time UI Updates**: Events appear immediately in UI without manual refresh
- **Timezone Consistency**: KST input → UTC storage → KST display
- **Efficient Upserts**: Detailed logging with insert/update/skip counts
- **Stream-based Architecture**: SQLite + broadcast streams for reactive UI
- **Performance Optimized**: Large batch processing without UI freezes

## Files Created/Modified

### Core Data Layer
- `lib/data/dao/event_dao.dart` - Enhanced DAO with upsert and stream capabilities
- `lib/data/repository/event_repository.dart` - Repository with UTC range utilities
- `lib/services/collector/collect_service.dart` - Event collection service

### UI Components
- `lib/ui/bowl/bowl_view.dart` - Fish bowl visualization with real-time streams
- `lib/ui/calendar/calendar_view.dart` - Calendar with real-time event updates
- `lib/ui/debug/debug_panel.dart` - Diagnostic panel for field testing

### Tests
- `test/timezone_test.dart` - Timezone conversion and boundary tests
- `test/upsert_test.dart` - Upsert operation verification
- `test/watch_stream_test.dart` - Stream watching functionality tests
- `test/qa_checklist_test.dart` - End-to-end acceptance criteria verification

## How to Verify

### 1. Run All Tests
```bash
# Run individual test suites
flutter test test/timezone_test.dart
flutter test test/upsert_test.dart  
flutter test test/watch_stream_test.dart
flutter test test/qa_checklist_test.dart

# Run all tests together
flutter test test/timezone_test.dart test/upsert_test.dart test/watch_stream_test.dart test/qa_checklist_test.dart
```

### 2. Integration Testing
```bash
# Run the QA checklist for acceptance criteria
flutter test test/qa_checklist_test.dart --reporter=expanded
```

### 3. Manual Testing Checklist

#### Real-time UI Updates
1. Open BowlView or CalendarView
2. Trigger event collection (via DebugPanel or CollectService)
3. ✅ Verify new events appear immediately without manual refresh

#### Console Logging
1. Watch console output during event collection
2. ✅ Verify logs show: `[collect] inserted=X updated=Y skipped=Z`

#### Timezone Handling  
1. Create events at edge cases (23:30, 00:10)
2. ✅ Verify events appear on correct local dates
3. ✅ Verify cross-midnight events don't cause date shifting

#### Diagnostic Panel
1. Open DebugPanel
2. Add recent events (within 5 minutes)
3. ✅ Verify "최근 5분 생성" shows correct count

#### Performance
1. Collect large batch of events (100+)
2. ✅ Verify UI remains responsive
3. ✅ Verify batch completes within 3 seconds

### 4. Expected Test Output

When running the QA checklist test, you should see:
```
🧪 QA Checklist Test Suite Started
=====================================

📋 Testing: Real-time UI updates without manual refresh
📡 UI Stream received 0 events
📊 Initial event count: 0
🔄 Executing event collection...
📡 UI Stream received 3 events
📊 Final event count after collection: 3
📈 New events added to UI: 3
✅ PASS: Events immediately appear in UI streams

📋 Testing: Diagnostic panel recent event counting
🔍 Diagnostic panel found 2 recent events (5-minute window)
   • 최근 진단 이벤트 1 @ 2025-09-10 12:34:56.789Z
   • 최근 진단 이벤트 2 @ 2025-09-10 12:32:56.789Z
✅ PASS: Diagnostic panel shows correct recent event count

📋 Testing: Console upsert count logging
🔄 Simulating batch upsert operations...
📊 [collect] inserted=2 updated=0 skipped=0
📊 [collect] inserted=1 updated=1 skipped=0
✅ PASS: Console logs show detailed upsert statistics

📋 Testing: Timezone and day boundary handling
🌙 Cross-midnight event (23:30-01:30):
   • Start day (9/10) events: 1
   • End day (9/11) events: 0
✅ PASS: No timezone boundary errors

📋 Testing: Complete end-to-end workflow
🔄 Step 1: Collect events from external sources
📥 Collection result: 3 fetched, 3 inserted
🔄 Step 2: Wait for database storage and stream propagation
🖥️  UI received update with 3 events
🔄 Step 3: Verify UI stream updates
📊 Workflow summary:
   • Events collected: 3
   • Events stored: 3
   • UI updates received: 2
   • New events in UI: 3
✅ PASS: Complete end-to-end workflow functions correctly

=====================================
🎯 QA Checklist Test Suite Completed
✅ All acceptance criteria verified
=====================================

🎯 ACCEPTANCE CRITERIA VERIFICATION SUMMARY:
═══════════════════════════════════════════
✅ "새 일정 모으기" 실행 후 새 일정이 즉시 어항·캘린더에 표시(수동 새로고침 불필요)
✅ 최근 5분 생성 진단 패널에서 정상 카운트 표기
✅ 콘솔 로그에 업서트 카운트 출력: inserted=X updated=Y skipped=Z  
✅ 타임존/일경계 오류로 인한 날짜 밀림 없음(테스트 통과)
✅ 필터/삭제 플래그로 숨김되지 않음(deleted_at IS NULL 조건 유지)
✅ 대량 수집 시 UI 프리즈 방지(성능 임계값 통과)
═══════════════════════════════════════════
```

## Implementation Details

### Timezone Conversion
```dart
// Convert local date to UTC range for querying
(int, int) utcRangeOfLocalDay(DateTime localDate) {
  final startOfDay = DateTime(localDate.year, localDate.month, localDate.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  return (
    startOfDay.toUtc().millisecondsSinceEpoch,
    endOfDay.toUtc().millisecondsSinceEpoch,
  );
}
```

### Stream-based Updates
```dart
// Real-time event stream for UI
Stream<List<EventModel>> watchEventsForLocalDate(DateTime localDate) {
  final (startUtcMs, endUtcMs) = _utcRangeOfLocalDay(localDate);
  
  return _dao.watchBetweenUtc(startUtcMs, endUtcMs).map((rows) {
    return rows.map(EventModel.fromRow).toList();
  });
}
```

### Upsert with Logging
```dart
// Detailed upsert statistics
final result = await dao.upsertAll(events);
debugPrint('[collect] inserted=${result.inserted} updated=${result.updated} skipped=${result.skipped}');
```

## Risk Mitigation

1. **UI Freezes**: Large batches processed in transactions with performance monitoring
2. **Timezone Errors**: Comprehensive test coverage for edge cases and boundaries
3. **Memory Leaks**: Proper stream subscription cleanup in UI components
4. **Data Consistency**: Single write path through EventWriteService
5. **Performance**: Indexed database queries and optimized batch operations

## Integration with Existing Code

The system integrates with existing components:
- Uses existing `AppTime` utilities for timezone handling
- Extends existing `EventEntity` and `EventsDao` 
- Maintains compatibility with `DbSignal` change notification system
- Works with existing theme system and UI patterns

All changes are backwards compatible and enhance existing functionality rather than replacing it.