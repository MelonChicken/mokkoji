import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/time/app_time.dart';
import '../features/events/data/event_entity.dart';
import '../data/models/today_summary_data.dart';

/// Debug overlay to verify timezone consistency in development
/// Shows raw DB value, UTC DateTime, and KST TZDateTime for each event
/// Only visible in debug builds
class TimeSanityOverlay extends StatelessWidget {
  final EventOccurrence occurrence;
  
  const TimeSanityOverlay({
    super.key,
    required this.occurrence,
  });

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeRow('RAW', occurrence.startTime.toIso8601String()),
            _buildTimeRow('UTC', occurrence.startTime.toIso8601String()),
            _buildTimeRow('KST', occurrence.startKst.toIso8601String()),
            _buildAssertionRow(occurrence),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeRow(String label, String value) {
    return Text(
      '$label: ${value.substring(11, 16)}', // Show only HH:mm
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontFamily: 'monospace',
      ),
    );
  }
  
  Widget _buildAssertionRow(EventOccurrence occurrence) {
    final isUtcValid = occurrence.startTime.isUtc;
    final color = isUtcValid ? Colors.green : Colors.red;
    final icon = isUtcValid ? '✓' : '✗';
    
    return Text(
      '$icon UTC',
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Debug widget to show comprehensive time information for an event
/// Shows all timezone conversions and validations
class TimeDebugCard extends StatelessWidget {
  final EventOccurrence occurrence;
  
  const TimeDebugCard({
    super.key,
    required this.occurrence,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TIME DEBUG: ${occurrence.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildDebugRow('Start UTC (DB)', occurrence.startTime),
            _buildDebugRow('End UTC (DB)', occurrence.endTime),
            _buildDebugRowTz('Start KST (UI)', occurrence.startKst),
            _buildDebugRowTz('End KST (UI)', occurrence.endKst),
            const SizedBox(height: 4),
            _buildValidationRow(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDebugRow(String label, DateTime dateTime) {
    final color = dateTime.isUtc ? Colors.green : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$label: ${dateTime.toIso8601String()}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
  
  Widget _buildDebugRowTz(String label, tz.TZDateTime dateTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$label: ${dateTime.toIso8601String()}',
        style: const TextStyle(
          color: Colors.lightBlue,
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
  
  Widget _buildValidationRow() {
    final startUtcValid = occurrence.startTime.isUtc;
    final endUtcValid = occurrence.endTime.isUtc;
    final kstValid = occurrence.startKst.location == AppTime.kst;
    
    return Row(
      children: [
        _buildValidationChip('UTC Start', startUtcValid),
        const SizedBox(width: 4),
        _buildValidationChip('UTC End', endUtcValid),
        const SizedBox(width: 4),
        _buildValidationChip('KST Zone', kstValid),
      ],
    );
  }
  
  Widget _buildValidationChip(String label, bool valid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: valid ? Colors.green[700] : Colors.red[700],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
        ),
      ),
    );
  }
}

/// Extension to add debug overlay to event cards
extension EventOccurrenceDebugExtension on EventOccurrence {
  
  /// Validate this occurrence's timezone consistency
  bool get isTimezoneValid {
    return startTime.isUtc && 
           endTime.isUtc && 
           startKst.location == AppTime.kst &&
           endKst.location == AppTime.kst;
  }
  
  /// Get debug info as formatted string
  String get debugTimeInfo {
    return '''
Event: $title
Start UTC: ${startTime.toIso8601String()} (isUtc: ${startTime.isUtc})
End UTC: ${endTime.toIso8601String()} (isUtc: ${endTime.isUtc})
Start KST: ${startKst.toIso8601String()}
End KST: ${endKst.toIso8601String()}
Valid: $isTimezoneValid
''';
  }
  
  /// Print debug info to console
  void debugPrintTimeInfo() {
    if (kDebugMode) {
      debugPrint('🕐 $debugTimeInfo');
    }
  }
}

/// Debug-only widget to verify stream consistency across screens
class StreamDebugOverlay extends StatelessWidget {
  final String screenName;
  final List<EventOccurrence> occurrences;
  final String streamSource;
  
  const StreamDebugOverlay({
    super.key,
    required this.screenName,
    required this.occurrences,
    required this.streamSource,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screenName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'SRC: $streamSource',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
              ),
            ),
            Text(
              'CNT: ${occurrences.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'HASH: ${occurrences.hashCode.toRadixString(16).substring(0, 4)}',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}