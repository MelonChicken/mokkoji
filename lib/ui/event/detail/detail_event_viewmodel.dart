import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/time/app_time.dart';
import '../../../core/time/kst.dart';
import '../../../data/providers/unified_providers.dart';
import '../../../data/services/event_write_service.dart';
import '../../../features/events/data/event_entity.dart';
import '../../../features/events/providers/events_providers.dart';

/// DetailEvent UI State with derived display properties
class DetailEventState {
  final EventEntity event;
  final String dateLine;           // "2025년 9월 10일 (수)"
  final String rangeLine;          // "13:16 – 14:46 · KST"
  final String? tzNote;            // ":sparkles: 자동 KST 변환" (오프셋이 있던 경우)
  final bool isCrossDay;           // 자정을 넘나드는지
  final List<String> sourceChips;  // ["구글", "내부"]
  final String syncState;          // "최근 동기화 19:24"
  final List<String>? mergedFrom;  // ["구글 캘린더", "네이버 일정"] (통합된 경우)
  final int? conflictCount;        // 같은 시간대 일정 수
  final bool isAllDay;
  final bool hasLocation;
  final bool hasDescription;
  final bool hasRecurrence;
  final bool hasReminder;
  final String? sourceUrl;         // External source URL for "원본 보기"
  final bool isEditable;           // Whether this event can be edited

  const DetailEventState({
    required this.event,
    required this.dateLine,
    required this.rangeLine,
    this.tzNote,
    required this.isCrossDay,
    required this.sourceChips,
    required this.syncState,
    this.mergedFrom,
    this.conflictCount,
    required this.isAllDay,
    required this.hasLocation,
    required this.hasDescription,
    required this.hasRecurrence,
    required this.hasReminder,
    this.sourceUrl,
    required this.isEditable,
  });
}

/// DetailEventViewModel - handles KST/UTC conversion and derived properties with real-time updates
class DetailEventViewModel extends FamilyAsyncNotifier<DetailEventState, String> {
  String get eventId => arg;

  @override
  Future<DetailEventState> build(String arg) async {
    // Watch the streaming event provider for real-time updates
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) throw Exception('Event not found: $eventId');
        return _buildDetailState(event);
      },
      loading: () => throw const AsyncLoading<DetailEventState>(),
      error: (error, stackTrace) => throw AsyncError(error, stackTrace),
    );
  }

  /// Build detailed state with proper KST/UTC conversion
  DetailEventState _buildDetailState(EventEntity event) {
    // 1. SAFE UTC PARSING - NO DIRECT ISO ACCESS
    final startUtc = KST.parseUtcIsoLenient(event.startDt);
    final endUtc = event.endDt != null ? KST.parseUtcIsoLenient(event.endDt!) : null;

    // 2. Convert to KST for display
    final startKst = AppTime.toKst(startUtc);
    final endKst = endUtc != null ? AppTime.toKst(endUtc) : null;

    // 3. Build display strings
    final dateLine = _buildDateLine(startKst, endKst, event.allDay);
    final rangeLine = _buildRangeLine(startKst, endKst, event.allDay);
    final tzNote = _buildTzNote(event.startDt);
    final isCrossDay = _checkCrossDay(startKst, endKst);

    // 4. Build source information
    final sourceChips = _buildSourceChips(event.sourcePlatform);
    final syncState = _buildSyncState(event.updatedAt);

    // 5. Build feature flags and source information
    final hasLocation = event.location?.isNotEmpty == true;
    final hasDescription = event.description?.isNotEmpty == true;
    final hasRecurrence = event.rrule?.isNotEmpty == true;
    final hasReminder = false; // TODO: implement reminder logic
    final sourceUrl = _buildSourceUrl(event);
    final isEditable = _checkEditability(event);

    return DetailEventState(
      event: event,
      dateLine: dateLine,
      rangeLine: rangeLine,
      tzNote: tzNote,
      isCrossDay: isCrossDay,
      sourceChips: sourceChips,
      syncState: syncState,
      isAllDay: event.allDay,
      hasLocation: hasLocation,
      hasDescription: hasDescription,
      hasRecurrence: hasRecurrence,
      hasReminder: hasReminder,
      sourceUrl: sourceUrl,
      isEditable: isEditable,
    );
  }

  /// Build date line: "2025년 9월 10일 (수)" or cross-day format
  String _buildDateLine(tz.TZDateTime startKst, tz.TZDateTime? endKst, bool allDay) {
    if (allDay) {
      if (endKst != null && !_isSameDay(startKst, endKst)) {
        return '${KST.dayWithWeekday(startKst.millisecondsSinceEpoch)} ~ ${KST.dayWithWeekday(endKst.millisecondsSinceEpoch)}';
      }
    }
    return KST.dayWithWeekday(startKst.millisecondsSinceEpoch);
  }

  /// Build time range line: "13:16 – 14:46 · KST"
  String _buildRangeLine(tz.TZDateTime startKst, tz.TZDateTime? endKst, bool allDay) {
    if (allDay) {
      return '종일';
    }
    
    if (endKst != null) {
      final startHm = AppTime.fmtHm(startKst);
      final endHm = AppTime.fmtHm(endKst);
      return '$startHm – $endHm · KST';
    }
    
    return '${AppTime.fmtHm(startKst)} · KST';
  }

  /// Build timezone note if conversion was applied
  String? _buildTzNote(String originalIso) {
    // If original had offset or was naive, show conversion note
    if (!originalIso.endsWith('Z')) {
      return '✨ 자동 KST 변환';
    }
    return null;
  }

  /// Check if event crosses midnight
  bool _checkCrossDay(tz.TZDateTime startKst, tz.TZDateTime? endKst) {
    if (endKst == null) return false;
    return !_isSameDay(startKst, endKst);
  }

  /// Check if two TZDateTime are on the same day
  bool _isSameDay(tz.TZDateTime dt1, tz.TZDateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }

  /// Build source platform chips
  List<String> _buildSourceChips(String sourcePlatform) {
    switch (sourcePlatform.toLowerCase()) {
      case 'google':
        return ['구글'];
      case 'naver':
        return ['네이버'];
      case 'kakao':
        return ['카카오'];
      case 'internal':
        return ['내부'];
      default:
        return [sourcePlatform];
    }
  }

  /// Build sync state message
  String _buildSyncState(String updatedAt) {
    try {
      final updatedUtc = KST.parseUtcIsoLenient(updatedAt);
      final updatedKst = AppTime.toKst(updatedUtc);
      final timeStr = AppTime.fmtHm(updatedKst);
      return '최근 동기화 $timeStr';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DetailVM] Failed to parse updated_at: $updatedAt ($e)');
      }
      return '동기화 정보 없음';
    }
  }

  /// Build source URL for external calendar links
  String? _buildSourceUrl(EventEntity event) {
    // Check if event has a direct URL
    if (event.url?.isNotEmpty == true) {
      return event.url;
    }

    // For external sources, we might construct URLs based on platform
    switch (event.sourcePlatform.toLowerCase()) {
      case 'google':
        // Google Calendar events might have iCal UID that can be used
        if (event.icalUid?.isNotEmpty == true) {
          // This would need to be constructed based on actual Google Calendar URL format
          // For now, return null until we have proper URL construction
          return null;
        }
        break;
      case 'naver':
      case 'kakao':
        // Similar for other platforms
        return null;
      case 'internal':
      default:
        // Internal events don't have external URLs
        return null;
    }

    return null;
  }

  /// Check if event can be edited
  bool _checkEditability(EventEntity event) {
    // Internal events are always editable
    if (event.sourcePlatform.toLowerCase() == 'internal') {
      return true;
    }

    // External events might be read-only depending on sync settings
    // For now, allow editing of synced events (they'll be updated locally)
    return true;
  }

  /// Delete event with confirmation
  Future<void> deleteEvent() async {
    final writeService = ref.read(eventWriteServiceProvider);
    await writeService.deleteEvent(eventId);
  }

  /// Share event details
  Future<void> shareEvent() async {
    final currentState = await future;
    final shareText = _buildShareText(currentState);

    // Use share_plus package or platform-specific sharing
    // For now, this is a placeholder - you'll need to add share_plus dependency
    if (kDebugMode) {
      debugPrint('Sharing event: $shareText');
    }

    // TODO: Implement actual sharing when share_plus is available
    // await Share.share(shareText, subject: event.title);
  }

  /// Build shareable text from event details
  String _buildShareText(DetailEventState state) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('📅 ${state.event.title}');
    buffer.writeln();

    // Date and time
    buffer.writeln('🕐 ${state.dateLine}');
    buffer.writeln('   ${state.rangeLine}');

    if (state.isCrossDay) {
      buffer.writeln('   (자정 넘김)');
    }

    buffer.writeln();

    // Location
    if (state.hasLocation) {
      buffer.writeln('📍 ${state.event.location}');
      buffer.writeln();
    }

    // Description
    if (state.hasDescription) {
      buffer.writeln('📝 ${state.event.description}');
      buffer.writeln();
    }

    // Source
    if (state.sourceChips.isNotEmpty) {
      buffer.writeln('출처: ${state.sourceChips.join(', ')}');
    }

    return buffer.toString().trim();
  }

  /// Retry loading event data
  void retry() {
    ref.invalidateSelf();
  }
}

/// Provider for DetailEventViewModel
final detailEventVmProvider = AsyncNotifierProvider.family<DetailEventViewModel, DetailEventState, String>(
  DetailEventViewModel.new,
);