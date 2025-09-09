/// KST (Korea Standard Time) 유틸리티 클래스
/// 설계 계약: DB는 항상 UTC 저장, 화면/계산은 항상 KST 기준
/// UI에서 직접 toLocal()/toUtc() 호출 금지 - AppTime만 사용
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AppTime {
  static late final tz.Location kst;
  static bool _inited = false;

  /// 앱 시작 시 반드시 호출 - main()에서 await AppTime.init() 
  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    kst = tz.getLocation('Asia/Seoul');
    _inited = true;
  }

  /// 현재 시각을 KST로 반환
  static tz.TZDateTime nowKst() => tz.TZDateTime.now(kst);

  /// DB → KST 변환 (DB에서 읽은 UTC 시간을 KST로)
  static tz.TZDateTime toKst(DateTime any) {
    assert(() {
      if (!any.isUtc) {
        // 디버그에서만 경고 로그 (빨간 화면 대신 원인 바로 잡기)
        if (kDebugMode) {
          debugPrint('[Time WARN] non-UTC DateTime passed to AppTime.toKst: $any');
        }
      }
      return true;
    }());
    final utc = any.isUtc ? any : any.toUtc(); // ✅ 런타임 방어
    return tz.TZDateTime.from(utc, kst);
  }

  /// KST(사용자 선택) → DB(UTC) 변환
  static DateTime fromKstToUtc(tz.TZDateTime kstTime) => kstTime.toUtc();

  /// KST의 연월일(시분초=0) 객체 생성 - copyWith() 대체
  static tz.TZDateTime ymdKst(int y, int m, int d) =>
      tz.TZDateTime(kst, y, m, d);

  /// KST 기준 하루의 경계 - tz.TZDateTime만 받도록 고정
  static tz.TZDateTime startOfDayKst(tz.TZDateTime k) =>
      tz.TZDateTime(kst, k.year, k.month, k.day);
  
  static tz.TZDateTime endOfDayKst(tz.TZDateTime k) =>
      tz.TZDateTime(kst, k.year, k.month, k.day + 1);

  /// 레거시 호환: DateTime을 받아서 KST 하루 시작 반환
  static tz.TZDateTime dayStartKst(DateTime date) {
    // date가 이미 KST인 경우를 가정하고 연월일만 추출
    return tz.TZDateTime(kst, date.year, date.month, date.day);
  }

  /// 시간 포맷터 (06:16 형태)
  static String fmtHm(tz.TZDateTime k) =>
      '${k.hour.toString().padLeft(2, '0')}:${k.minute.toString().padLeft(2, '0')}';

  /// 범위 표시 "06:16 - 07:16"
  static String fmtRange(tz.TZDateTime s, tz.TZDateTime e) =>
      '${fmtHm(s)} - ${fmtHm(e)}';

  /// KST 기준 자정부터의 분 수 계산 (타임라인 배치용)
  static int minutesFromMidnightKst(tz.TZDateTime kstTime) {
    return kstTime.hour * 60 + kstTime.minute;
  }

  /// 두 날짜가 KST 기준으로 같은 날인지 확인
  static bool isSameDayKst(tz.TZDateTime a, tz.TZDateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// DB에서 UTC 밀리초 → DateTime 복원 (UTC 플래그 보장)
  static DateTime fromDbUtc(int millisSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);

  /// 레거시: 기존 코드 호환용 (단계적 마이그레이션)
  @Deprecated('Use toKst() instead')
  static DateTime toKstLegacy(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, kst);
  }

  @Deprecated('Use nowKst() instead')  
  static DateTime nowKstLegacy() {
    return tz.TZDateTime.now(kst);
  }

  @Deprecated('Use minutesFromMidnightKst() instead')
  static int minutesFromMidnightKstLegacy(DateTime dateTime) {
    final kstTime = tz.TZDateTime.from(dateTime, kst);
    return kstTime.hour * 60 + kstTime.minute;
  }
}