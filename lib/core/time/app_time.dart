/// KST (Korea Standard Time) 유틸리티 클래스
/// 설계 요지: 저장은 UTC, 표시/'지금'/타임라인 기준은 KST 고정.
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppTime {
  static tz.Location? _kst;
  
  /// 타임존 데이터 초기화 (앱 시작 시 한 번 호출)
  static Future<void> ensureInitialized() async {
    tz.initializeTimeZones();
    _kst = tz.getLocation('Asia/Seoul');
  }
  
  /// 현재 시각을 KST로 반환
  static DateTime nowKst() {
    return tz.TZDateTime.now(_kst ?? tz.local);
  }
  
  /// 임의의 DateTime을 KST로 변환
  static DateTime toKst(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, _kst ?? tz.local);
  }
  
  /// KST에서 UTC로 변환
  static DateTime fromKstToUtc(DateTime kstDateTime) {
    final tzDateTime = tz.TZDateTime.from(kstDateTime, _kst ?? tz.local);
    return tzDateTime.toUtc();
  }
  
  /// KST 기준 하루의 시작 시각 (00:00:00)
  static DateTime dayStartKst(DateTime kstDate) {
    return DateTime(kstDate.year, kstDate.month, kstDate.day);
  }
  
  /// KST 기준 하루의 종료 시각 (다음날 00:00:00, exclusive)
  static DateTime dayEndExclusiveKst(DateTime kstDate) {
    return dayStartKst(kstDate).add(const Duration(days: 1));
  }
  
  /// KST 기준 자정부터의 분 수 계산
  static int minutesFromMidnightKst(DateTime dateTime) {
    final kstTime = toKst(dateTime);
    return kstTime.hour * 60 + kstTime.minute;
  }
  
  /// 오늘 KST 기준의 날짜 범위 반환
  static (DateTime start, DateTime end) todayRangeKst() {
    final now = nowKst();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (startOfDay, endOfDay);
  }
  
  /// 두 날짜가 KST 기준으로 같은 날인지 확인
  static bool isSameDayKst(DateTime a, DateTime b) {
    final kstA = toKst(a);
    final kstB = toKst(b);
    return kstA.year == kstB.year && 
           kstA.month == kstB.month && 
           kstA.day == kstB.day;
  }
}