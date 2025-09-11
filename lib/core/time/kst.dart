/// KST (Korea Standard Time) 강제 표시 유틸리티
/// 기기 타임존에 관계없이 항상 KST 기준으로 시간을 표시합니다.
/// 
/// 사용법:
/// - 앱 초기화 시 KST.init() 호출 필수
/// - 모든 시간 표시는 KST.* 헬퍼 함수 사용
/// - UTC milliseconds를 KST 포맷으로 변환
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class KST {
  static bool _inited = false;
  static late tz.Location _seoul;

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

  /// ISO8601 UTC 문자열을 KST 날짜 포맷으로 변환 (기존 시스템 호환용)
  /// @param isoString UTC ISO8601 문자열 (예: "2025-09-10T02:00:00.000Z")
  /// @return "yyyy년 MM월 dd일" 형태의 한국어 날짜
  static String dayFromIso(String isoString) {
    final utcDateTime = DateTime.parse(isoString);
    assert(utcDateTime.isUtc, 'ISO 문자열은 UTC 시간이어야 합니다');
    final ms = utcDateTime.millisecondsSinceEpoch;
    return day(ms);
  }

  /// ISO8601 UTC 문자열을 KST 시간 포맷으로 변환 (기존 시스템 호환용)
  /// @param isoString UTC ISO8601 문자열
  /// @return "HH:mm" 형태의 24시간 시간
  static String hmFromIso(String isoString) {
    final utcDateTime = DateTime.parse(isoString);
    assert(utcDateTime.isUtc, 'ISO 문자열은 UTC 시간이어야 합니다');
    final ms = utcDateTime.millisecondsSinceEpoch;
    return hm(ms);
  }

  /// ISO8601 UTC 문자열들로 시간 범위를 포맷팅 (기존 시스템 호환용)
  /// @param startIso 시작 시간 UTC ISO8601 문자열
  /// @param endIso 종료 시간 UTC ISO8601 문자열 (null이면 시작 시간만)
  /// @return "HH:mm" 또는 "HH:mm - HH:mm" 형태
  static String rangeFromIso(String startIso, String? endIso) {
    if (endIso == null) {
      return hmFromIso(startIso);
    }
    return '${hmFromIso(startIso)} - ${hmFromIso(endIso)}';
  }
}