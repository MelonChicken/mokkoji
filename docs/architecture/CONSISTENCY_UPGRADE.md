# Event Schedule Consistency - Stream Stabilization Upgrade

## 🎯 목표 달성

✅ **단일화 + 안정화**: `DateKey` 값 객체로 안정적인 스트림 파라미터  
✅ **keepAlive + broadcast**: 재구독 폭주 방지  
✅ **완전 opt-in 디버그**: `--dart-define=MOKKOJI_DEVTOOLS=true`로만 표시  
✅ **추적 가능 로깅**: 구독→방출→UI 수신 순서 로그  
✅ **초기 로딩 개선**: 타임라인 'jump to now' 안정화

## 🔧 핵심 변경사항

### 1. DateKey 값 객체 도입
```dart
// lib/core/time/date_key.dart
class DateKey {
  final int y, m, d;
  const DateKey(this.y, this.m, this.d);
  factory DateKey.fromKst(DateTime k) => DateKey(k.year, k.month, k.day);
  
  @override
  bool operator ==(Object o) => o is DateKey && o.y==y && o.m==m && o.d==d;
  @override
  int get hashCode => Object.hash(y,m,d);
}
```
**효과**: Provider family 파라미터가 안정적이어서 불필요한 재구축 방지

### 2. 안정화된 Provider
```dart
final occurrencesForDayProvider = StreamProvider.family.autoDispose<List<EventOccurrence>, DateKey>((ref, key) {
  // ✅ keepAlive로 화면 생명주기 중 dispose 방지
  final link = ref.keepAlive();
  ref.onCancel(() {
    Future.delayed(const Duration(minutes: 5), link.close);
  });

  final repository = ref.watch(unifiedEventRepositoryProvider);
  return repository.watchOccurrencesForDayKey(key);
});
```
**효과**: 탭 전환/rebuild 시 스트림이 재구독되지 않음

### 3. 통합 스트림 + 강화된 로깅
```dart
Stream<List<EventOccurrence>> watchOccurrencesForDayKey(DateKey key) {
  // 로깅: 구독 시작
  if (kDebugMode) debugPrint('▶ watch start $key');
  
  return DbSignal.instance.eventsStream.asyncMap((_) async {
    // ... 데이터 처리 ...
    
    // 로깅: 방출
    if (kDebugMode) debugPrint('● emit $key count=${corrected.length}');
    
    return corrected;
  }).asBroadcastStream(); // ✅ 중복 구독 안전
}
```
**효과**: 로그로 "무한 로딩" 원인 즉시 파악 가능

### 4. 완전 opt-in 디버그 도구
```dart
// lib/devtools/dev_config.dart
const bool kEnableDevTools = bool.fromEnvironment(
  'MOKKOJI_DEVTOOLS', 
  defaultValue: false,
);

// 사용처
if (kEnableDevTools && kDebugMode) const ConsistencyDebugPanel(),
```
**사용법**:
```bash
# 기본: 디버그 도구 숨김
flutter run

# 디버그 도구 표시
flutter run --dart-define=MOKKOJI_DEVTOOLS=true
```

### 5. 타임라인 초기 점프 강화
```dart
// DayTimelineView에서 개선
void jumpToInclude(DateTime target, {double anchor = 0.35, bool animate = false}) {
  final tryJump = () {
    if (!mounted) return false;
    if (!_scrollController.hasClients) {
      // ✅ 컨트롤러 준비 안됨 → pending으로 저장
      _pendingTarget = target;
      return false;
    }
    // ... 실제 점프 로직
  };
  
  // ✅ 3회 재시도 + 위젯 업데이트 시 재시도
}
```

### 6. UI에서 데이터 로딩 시 점프 트리거
```dart
// home_screen.dart
data: (occurrences) {
  // ✅ 데이터 로딩 완료 시 초기 점프 실행
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _jumpToNowInitial();
  });
  
  return _DayTimelineViewWrapper(...);
},
```

## 📊 로그 패턴 (정상 동작)

홈 진입 직후 콘솔에서 이 순서가 보이면 **OK**:
```
▶ watch start 2025-09-09
● emit 2025-09-09 count=5
UI got 2025-09-09 count=5
```

## 🚨 문제 진단

### "무한 로딩" 경우
- `▶ watch start`만 반복 → 데이터베이스/쿼리 문제
- `● emit`이 없음 → repository 내부 오류  
- `UI got`이 없음 → provider 구독 문제

### 재구독 폭주
- 스크롤/탭 전환 시 `▶ watch start` 연속 발생
- **해결**: `keepAlive()` 덕분에 화면 유지 중엔 방지됨

## ✅ 수용 기준

1. **홈/통합/요약** 동일 날짜에서 **같은 건수, 같은 다음 일정**  
2. **1초 내 로딩 완료** + 로그에 정상 패턴 출현  
3. **기본 상태에서 디버그 패널 미표시**  
4. **오프라인 시 저장된 일정 표시** (오프라인 배지는 정보용)  
5. **초기 진입 시 'now'로 자동 스크롤**

## 🔄 비상 옵션

여전히 문제가 있다면:
```dart
// keepAlive 일시 해제
final occurrencesForDayProvider = StreamProvider.family<List<EventOccurrence>, DateKey>((ref, key) {
  // autoDispose 제거
  final repository = ref.watch(unifiedEventRepositoryProvider);
  return repository.watchOccurrencesForDayKey(key);
});
```

하지만 **repository의 `.asBroadcastStream()`은 꼭 유지**해야 첫 화면 진입 시 즉시 값 재사용됨.

---

이제 **단일 스트림**으로 모든 화면이 **일관된 데이터**를 표시하며, **안정적인 구독**으로 성능도 향상되었습니다! 🚀