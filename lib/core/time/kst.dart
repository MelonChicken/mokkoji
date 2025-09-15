/// KST (Korea Standard Time) 강제 표시 유틸리티
/// 기기 타임존에 관계없이 항상 KST 기준으로 시간을 표시합니다.
/// 
/// 사용법:
/// - 앱 초기화 시 KST.init() 호출 필수
/// - 모든 시간 표시는 KST.* 헬퍼 함수 사용
/// - UTC milliseconds를 KST 포맷으로 변환
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class KST {
  static bool _inited = false;
  static late tz.Location _seoul;
  
  // Regex to detect timezone offset in ISO strings
  static final _offsetRegex = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  /// KST 초기화 - 앱 시작 시 반드시 호출
  /// tzdata를 로드하고 Asia/Seoul 타임존을 설정합니다.
  static void init() {
    if (_inited) return;
    
    tzdata.initializeTimeZones();
    _seoul = tz.getLocation('Asia/Seoul');
    _inited = true;
  }

  /// UTC milliseconds를 KST TZDateTime으로 변환
  /// @param ms UTC 기준 milliseconds since epoch
  /// @return KST 타임존의 TZDateTime 객체
  static tz.TZDateTime fromUtcMs(int ms) {
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');
    final utc = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return tz.TZDateTime.from(utc, _seoul);
  }

  /// 현재 KST 시간 반환
  static tz.TZDateTime now() {
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');
    return tz.TZDateTime.now(_seoul);
  }

  /// UTC milliseconds를 KST 날짜 포맷으로 변환
  /// @param ms UTC milliseconds
  /// @return "yyyy년 MM월 dd일" 형태의 한국어 날짜
  static String day(int ms) {
    final kstTime = fromUtcMs(ms);
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(kstTime);
  }

  /// UTC milliseconds를 KST 시간 포맷으로 변환
  /// @param ms UTC milliseconds
  /// @return "HH:mm" 형태의 24시간 시간
  static String hm(int ms) {
    final kstTime = fromUtcMs(ms);
    return DateFormat('HH:mm', 'ko_KR').format(kstTime);
  }

  /// 시간 범위를 포맷팅
  /// @param startMs 시작 시간 UTC milliseconds
  /// @param endMs 종료 시간 UTC milliseconds (null이면 시작 시간만)
  /// @return "HH:mm" 또는 "HH:mm - HH:mm" 형태
  static String range(int startMs, int? endMs) {
    if (endMs == null) {
      return hm(startMs);
    }
    return '${hm(startMs)} - ${hm(endMs)}';
  }

  /// 상세한 날짜시간 포맷
  /// @param ms UTC milliseconds
  /// @return "yyyy년 MM월 dd일 HH:mm" 형태
  static String dayTime(int ms) {
    final kstTime = fromUtcMs(ms);
    return DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR').format(kstTime);
  }

  /// 요일 포함 날짜 포맷
  /// @param ms UTC milliseconds  
  /// @return "yyyy년 MM월 dd일 (월)" 형태
  static String dayWithWeekday(int ms) {
    final kstTime = fromUtcMs(ms);
    return DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(kstTime);
  }

  /// 상대적 시간 표시 (예: "2시간 후", "1일 전")
  /// @param ms UTC milliseconds
  /// @return 현재 시간 기준 상대적 시간 문자열
  static String relative(int ms) {
    final kstTime = fromUtcMs(ms);
    final nowKst = now();
    final difference = kstTime.difference(nowKst);

    if (difference.isNegative) {
      final absDiff = -difference.inMinutes;
      if (absDiff < 60) {
        return '${absDiff}분 전';
      } else if (absDiff < 1440) {
        return '${absDiff ~/ 60}시간 전';
      } else {
        return '${absDiff ~/ 1440}일 전';
      }
    } else {
      final diffMinutes = difference.inMinutes;
      if (diffMinutes < 60) {
        return '${diffMinutes}분 후';
      } else if (diffMinutes < 1440) {
        return '${diffMinutes ~/ 60}시간 후';
      } else {
        return '${diffMinutes ~/ 1440}일 후';
      }
    }
  }

  /// 두 UTC 시간이 KST 기준으로 같은 날인지 확인
  /// @param ms1 첫 번째 UTC milliseconds
  /// @param ms2 두 번째 UTC milliseconds
  /// @return 같은 KST 날짜면 true
  static bool isSameDay(int ms1, int ms2) {
    final kst1 = fromUtcMs(ms1);
    final kst2 = fromUtcMs(ms2);
    
    return kst1.year == kst2.year && 
           kst1.month == kst2.month && 
           kst1.day == kst2.day;
  }

  /// KST 기준 하루의 시작 시간을 UTC milliseconds로 반환
  /// @param ms 기준이 될 UTC milliseconds
  /// @return KST 기준 해당 날짜 00:00의 UTC milliseconds
  static int startOfDay(int ms) {
    final kstTime = fromUtcMs(ms);
    final startOfDay = tz.TZDateTime(_seoul, kstTime.year, kstTime.month, kstTime.day);
    return startOfDay.toUtc().millisecondsSinceEpoch;
  }

  /// KST 기준 하루의 끝 시간을 UTC milliseconds로 반환
  /// @param ms 기준이 될 UTC milliseconds  
  /// @return KST 기준 해당 날짜 다음날 00:00의 UTC milliseconds
  static int endOfDay(int ms) {
    final kstTime = fromUtcMs(ms);
    final endOfDay = tz.TZDateTime(_seoul, kstTime.year, kstTime.month, kstTime.day + 1);
    return endOfDay.toUtc().millisecondsSinceEpoch;
  }

  /// KST DateTime을 UTC milliseconds로 변환 (입력용)
  /// @param year KST 기준 년
  /// @param month KST 기준 월  
  /// @param day KST 기준 일
  /// @param hour KST 기준 시간 (기본값: 0)
  /// @param minute KST 기준 분 (기본값: 0)
  /// @return UTC milliseconds since epoch
  static int toUtcMs({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');
    final kstDateTime = tz.TZDateTime(_seoul, year, month, day, hour, minute, second);
    return kstDateTime.toUtc().millisecondsSinceEpoch;
  }

  /// 디버그용: KST 초기화 상태 확인
  static bool get isInitialized => _inited;

  /// 디버그용: 현재 KST 타임존 정보
  static String get timezoneInfo => _inited ? _seoul.name : 'Not initialized';

  /// Lenient UTC parser: 모든 ISO 형태를 UTC DateTime으로 보정
  /// 
  /// 다양한 ISO 형태를 처리:
  /// - "2025-09-10T02:00:00.000Z" (UTC) → 그대로 반환
  /// - "2025-09-10T11:00:00.000+09:00" (오프셋) → UTC로 변환
  /// - "2025-09-10T02:00:00.000" (naive) → KST로 해석 후 UTC 변환
  /// 
  /// @param iso ISO8601 문자열 (모든 형태 허용)
  /// @return UTC DateTime (항상 isUtc: true)
  static DateTime parseUtcIsoLenient(String iso) {
    final dt = DateTime.parse(iso);
    
    // 이미 UTC인 경우 그대로 반환
    if (dt.isUtc) return dt;
    
    // 오프셋이 명시된 경우: toUtc()로 정확한 UTC 변환
    if (_offsetRegex.hasMatch(iso)) {
      return dt.toUtc();
    }
    
    // 오프셋이 없는 'naive' ISO는 과거 데이터로 간주
    // KST로 해석한 후 UTC로 변환 (기존 데이터 호환성)
    if (kDebugMode) {
      debugPrint('[time] coerced non-utc iso: $iso');
    }
    
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');
    final kdt = tz.TZDateTime(_seoul, dt.year, dt.month, dt.day, 
                              dt.hour, dt.minute, dt.second, 
                              dt.millisecond, dt.microsecond);
    return kdt.toUtc();
  }

  /// ISO8601 문자열을 KST 날짜 포맷으로 변환 (관용 파서 사용)
  /// @param isoString ISO8601 문자열 (모든 형태 허용)
  /// @return "yyyy년 MM월 dd일" 형태의 한국어 날짜
  static String dayFromIso(String isoString) {
    final utcDateTime = parseUtcIsoLenient(isoString);
    final ms = utcDateTime.millisecondsSinceEpoch;
    return day(ms);
  }

  /// ISO8601 문자열을 KST 시간 포맷으로 변환 (관용 파서 사용)
  /// @param isoString ISO8601 문자열 (모든 형태 허용)
  /// @return "HH:mm" 형태의 24시간 시간
  static String hmFromIso(String isoString) {
    final utcDateTime = parseUtcIsoLenient(isoString);
    final ms = utcDateTime.millisecondsSinceEpoch;
    return hm(ms);
  }

  /// ISO8601 문자열들로 시간 범위를 포맷팅 (관용 파서 사용)
  /// @param startIso 시작 시간 ISO8601 문자열 (모든 형태 허용)
  /// @param endIso 종료 시간 ISO8601 문자열 (null이면 시작 시간만)
  /// @return "HH:mm" 또는 "HH:mm - HH:mm" 형태
  static String rangeFromIso(String startIso, String? endIso) {
    if (endIso == null) {
      return hmFromIso(startIso);
    }
    return '${hmFromIso(startIso)} - ${hmFromIso(endIso)}';
  }

  // ===== New methods for repeat engine =====

  /// Convert UTC ISO string to KST DateTime
  /// @param isoString UTC ISO8601 string (e.g., "2025-09-14T02:00:00.000Z")
  /// @return KST DateTime (not timezone-aware, just adjusted for display)
  static DateTime fromUtcIso(String isoString) {
    final utc = parseUtcIsoLenient(isoString);
    final kstTz = fromUtcMs(utc.millisecondsSinceEpoch);
    // Convert to regular DateTime for easier arithmetic
    return DateTime(kstTz.year, kstTz.month, kstTz.day,
                   kstTz.hour, kstTz.minute, kstTz.second,
                   kstTz.millisecond, kstTz.microsecond);
  }

  /// Convert KST DateTime to UTC ISO string
  /// @param kstDateTime KST DateTime (will be treated as KST)
  /// @return UTC ISO8601 string with Z suffix
  static String toUtcIso(DateTime kstDateTime) {
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');

    // Treat input as KST and convert to UTC
    final kstTz = tz.TZDateTime(_seoul,
      kstDateTime.year, kstDateTime.month, kstDateTime.day,
      kstDateTime.hour, kstDateTime.minute, kstDateTime.second,
      kstDateTime.millisecond, kstDateTime.microsecond
    );

    return kstTz.toUtc().toIso8601String();
  }

  /// Get start of day for KST DateTime
  /// @param kstDateTime KST DateTime
  /// @return KST DateTime at 00:00:00
  static DateTime atStartOfDay(DateTime kstDateTime) {
    return DateTime(kstDateTime.year, kstDateTime.month, kstDateTime.day);
  }

  /// Get end of day for KST DateTime
  /// @param kstDateTime KST DateTime
  /// @return KST DateTime at 23:59:59.999
  static DateTime atEndOfDay(DateTime kstDateTime) {
    return DateTime(kstDateTime.year, kstDateTime.month, kstDateTime.day, 23, 59, 59, 999);
  }

  /// Round down to start of minute (for comparing recurrence exceptions)
  /// @param kstDateTime KST DateTime
  /// @return KST DateTime with seconds/milliseconds zeroed
  static DateTime atStartOfMinute(DateTime kstDateTime) {
    return DateTime(kstDateTime.year, kstDateTime.month, kstDateTime.day,
                   kstDateTime.hour, kstDateTime.minute);
  }

  /// Convert KST DateTime to day key string
  /// @param kstDateTime KST DateTime
  /// @return 'YYYY-MM-DD' day key string
  static String dayKey(DateTime kstDateTime) {
    return '${kstDateTime.year.toString().padLeft(4, '0')}-'
           '${kstDateTime.month.toString().padLeft(2, '0')}-'
           '${kstDateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get current KST as regular DateTime (for calculations)
  /// @return Current KST as DateTime
  static DateTime nowAsDateTime() {
    final kstTz = now();
    return DateTime(kstTz.year, kstTz.month, kstTz.day,
                   kstTz.hour, kstTz.minute, kstTz.second,
                   kstTz.millisecond, kstTz.microsecond);
  }

  // ===== Enhanced methods for repeat materialization =====

  /// Create KST TZDateTime from UTC DateTime for recurrence expansion
  /// @param utc UTC DateTime to convert
  /// @return TZDateTime anchored in Asia/Seoul
  static tz.TZDateTime kstAnchorFromUtc(DateTime utc) {
    assert(_inited, 'KST.init()을 먼저 호출해야 합니다.');
    return tz.TZDateTime.from(utc.isUtc ? utc : utc.toUtc(), _seoul);
  }

  /// Convert KST TZDateTime to UTC DateTime for storage
  /// @param kstDt KST TZDateTime
  /// @return UTC DateTime ready for storage
  static DateTime utcFromKst(tz.TZDateTime kstDt) {
    return kstDt.toUtc();
  }

  /// Get date key from TZDateTime for provider invalidation
  /// @param tzDateTime TZDateTime (should be KST)
  /// @return 'YYYY-MM-DD' date key
  static String dateKeyFromTz(tz.TZDateTime tzDateTime) {
    return '${tzDateTime.year.toString().padLeft(4, '0')}-'
           '${tzDateTime.month.toString().padLeft(2, '0')}-'
           '${tzDateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get all affected date keys for cross-day events
  /// @param startKst Start time in KST
  /// @param endKst End time in KST
  /// @return Set of date keys that this event touches
  static Set<String> getAffectedDateKeys(tz.TZDateTime startKst, tz.TZDateTime endKst) {
    final keys = <String>{};

    // Always include start date
    keys.add(dateKeyFromTz(startKst));

    // If event crosses midnight, include end date too
    if (startKst.day != endKst.day || startKst.month != endKst.month || startKst.year != endKst.year) {
      keys.add(dateKeyFromTz(endKst));
    }

    return keys;
  }
}