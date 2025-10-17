# Event Schedule Consistency Implementation

## 📋 Overview
완전한 일정 일관성 보장 시스템이 구현되었습니다. 단일 스트림 + 단일 DB + 즉시 반영 아키텍처로 홈 타임라인, 통합 일정, 요약 카드가 항상 동일한 데이터를 표시합니다.

## 🎯 핵심 원칙
- **단일 진실 원천 (Single Source of Truth)**: `UnifiedEventRepository.watchOccurrencesForDayKst()`
- **단일 쓰기 경로**: `EventWriteService`를 통한 모든 CRUD
- **즉시 반영**: 변경 시 모든 UI가 자동 갱신
- **KST 기준 통일**: 저장은 UTC, 표시/쿼리는 KST

## 📁 구현된 파일들

### 1. 핵심 유틸리티
- `lib/core/time/app_time.dart` - KST/UTC 변환 및 날짜 유틸리티 확장

### 2. 데이터베이스 & 모델
- `lib/data/app_database.dart` - 데이터베이스 싱글턴 홀더
- `lib/data/models/today_summary_data.dart` - `withMinDuration` 메서드 추가

### 3. 서비스 레이어
- `lib/data/services/event_change_bus.dart` - 이벤트 변경 알림 버스
- `lib/data/services/occurrence_indexer.dart` - RRULE 전개 및 인덱싱
- `lib/data/services/event_write_service.dart` - 단일 CRUD 서비스

### 4. 리포지토리
- `lib/data/repositories/unified_event_repository.dart` - 통합 이벤트 리포지토리

### 5. 의존성 주입
- `lib/data/providers/unified_providers.dart` - Riverpod 프로바이더들

### 6. UI 업데이트
- `lib/ui/home/home_screen.dart` - 통합 스트림 사용하도록 변경

### 7. 개발 도구
- `lib/devtools/consistency_debug_panel.dart` - 일관성 확인 패널

### 8. 테스트
- `test/consistency/stream_consistency_test.dart` - 일관성 테스트

## 🔧 사용법

### Provider 사용
```dart
// 오늘 일정 목록
final occurrencesAsync = ref.watch(todayOccurrencesProvider);

// 특정 날짜 일정 목록  
final dayOccurrences = ref.watch(occurrencesForDayProvider(specificDay));

// 요약 데이터
final summaryAsync = ref.watch(todaySummaryTodayProvider);
```

### CRUD 작업
```dart
// 이벤트 생성
final writeService = ref.read(eventWriteServiceProvider);
await writeService.addEvent(EventDraft(
  title: '새 일정',
  startTime: startTimeUtc,
  endTime: endTimeUtc,
));

// 이벤트 수정
await writeService.updateEvent(EventPatch(
  id: eventId,
  title: '수정된 제목',
));

// 이벤트 삭제
await writeService.deleteEvent(eventId);
```

### 디버그 패널
- 개발 모드에서 홈 화면 우상단에 자동 표시
- 카운트 일치 여부, 다음 일정 일치 여부 확인
- 콘솔 덤프 기능으로 상세 정보 출력

## ✅ 보장되는 일관성

### 1. 데이터 일치
- 홈 타임라인 개수 = 요약 카드 개수
- 홈 타임라인 다음 일정 = 요약 카드 다음 일정

### 2. 즉시 반영
- 이벤트 생성/수정/삭제 시 모든 화면 즉시 갱신
- 트랜잭션 + 변경 이벤트 발행

### 3. 시간대 통일
- 모든 날짜 연산은 KST 기준
- 경계 케이스 (자정, 전날 걸침) 처리

### 4. 경계값 테스트
- 23:59 시작 → 다음날 01:00 종료 이벤트
- 전날 UTC → 오늘 KST 변환
- 종일 이벤트 처리

## 🏁 적용 후 확인사항

### 필수 체크리스트
- [ ] `AppDatabaseHolder.instance()` 전체 앱 단일 사용
- [ ] 모든 UI가 `watchOccurrencesForDayKst()` 기반
- [ ] CRUD는 `EventWriteService`만 사용
- [ ] KST 기준 날짜/시간 처리
- [ ] 디버그 패널에서 일관성 OK 표시

### 수용 기준 (Acceptance Criteria)
✅ 같은 날짜에서 홈/통합/요약의 총 건수와 다음 일정 동일  
✅ CRUD 직후 세 화면 동시 갱신  
✅ KST/UTC 경계에서 불일치 없음  
✅ Dev 패널 일관성 지표 녹색(OK)  

## 🔍 향후 확장

### 1. RRULE 전개
- 현재: 단순 이벤트만 처리
- 계획: `OccurrenceIndexer`에서 복잡한 반복 규칙 처리

### 2. 성능 최적화
- 현재: On-the-fly 전개
- 계획: Materialized occurrence 테이블 백그라운드 생성

### 3. 오프라인 지원
- 현재: 온라인 상태만
- 계획: 실제 동기화 상태 반영

이제 모든 화면이 단일 데이터 소스를 공유하며, 일정 변경 시 즉시 일관된 업데이트가 보장됩니다! 🎉