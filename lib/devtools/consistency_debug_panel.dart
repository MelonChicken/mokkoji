import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/unified_providers.dart';
import '../data/models/today_summary_data.dart';
import '../core/time/app_time.dart';
import '../core/time/date_key.dart';
import 'dev_config.dart';

/// Debug panel for checking event consistency across all UI screens
/// Shows count mismatches, database hash, and detailed event lists
class ConsistencyDebugPanel extends ConsumerStatefulWidget {
  const ConsistencyDebugPanel({super.key});

  @override
  ConsumerState<ConsistencyDebugPanel> createState() => _ConsistencyDebugPanelState();
}

class _ConsistencyDebugPanelState extends ConsumerState<ConsistencyDebugPanel> {
  bool _isExpanded = false;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    // Only show if explicitly enabled
    if (!kEnableDevTools) return const SizedBox.shrink();
    
    if (!_isExpanded) {
      return Positioned(
        top: 100,
        right: 16,
        child: FloatingActionButton.small(
          heroTag: "debug_panel",
          backgroundColor: Colors.purple.withValues(alpha: 0.8),
          onPressed: () => setState(() => _isExpanded = true),
          child: const Icon(Icons.bug_report, color: Colors.white),
        ),
      );
    }

    final todayKey = ref.watch(todayKeyProvider);
    final checkKey = _selectedDate != null 
        ? DateKey.fromKst(_selectedDate!) 
        : todayKey;
    
    // Watch both streams for comparison
    final occurrencesAsync = ref.watch(occurrencesForDayProvider(checkKey));
    final summaryAsync = ref.watch(todaySummaryProvider(checkKey));
    final dbInstance = ref.watch(appDatabaseProvider);

    return Positioned(
      top: 100,
      right: 16,
      left: 16,
      child: Card(
        color: Colors.purple.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'Consistency Debug',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _isExpanded = false),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date selector
              Row(
                children: [
                  const Text('날짜: '),
                  TextButton(
                    onPressed: () => _selectDate(),
                    child: Text(
                      checkKey.toString(),
                      style: const TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Database instance hash
              Text(
                'DB Hash: ${dbInstance.hashCode.toString().substring(0, 8)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.purple,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Consistency checks
              Consumer(
                builder: (context, ref, _) {
                  return occurrencesAsync.when(
                    loading: () => const Text('Loading occurrences...'),
                    error: (error, stack) => Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    data: (occurrences) {
                      return summaryAsync.when(
                        loading: () => const Text('Loading summary...'),
                        error: (error, stack) => Text('Error: $error', style: const TextStyle(color: Colors.red)),
                        data: (summary) => _buildConsistencyChecks(occurrences, summary),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Debug dump button
              ElevatedButton.icon(
                onPressed: () => _dumpToConsole(checkKey),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Console Dump'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsistencyChecks(List<EventOccurrence> occurrences, TodaySummaryData summary) {
    final countMatch = occurrences.length == summary.count;
    final nextMatch = _checkNextEventMatch(occurrences, summary);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              countMatch ? Icons.check_circle : Icons.error,
              color: countMatch ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text('Count: TL=${occurrences.length}, SUM=${summary.count}'),
          ],
        ),
        
        const SizedBox(height: 4),
        
        Row(
          children: [
            Icon(
              nextMatch ? Icons.check_circle : Icons.error,
              color: nextMatch ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Next: ${_getNextComparison(occurrences, summary)}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        if (!countMatch || !nextMatch) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INCONSISTENCY DETECTED!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (!countMatch)
                  Text('Count mismatch: ${occurrences.length} vs ${summary.count}'),
                if (!nextMatch)
                  Text('Next event mismatch: ${_getNextComparison(occurrences, summary)}'),
              ],
            ),
          ),
        ],
        
        // Show first few events for verification
        if (occurrences.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('First 3 events:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ...occurrences.take(3).map((occ) => Text(
            '  ${occ.startKst.hour.toString().padLeft(2, '0')}:${occ.startKst.minute.toString().padLeft(2, '0')} ${occ.title}',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          )),
        ],
      ],
    );
  }

  bool _checkNextEventMatch(List<EventOccurrence> occurrences, TodaySummaryData summary) {
    final now = AppTime.nowKst();
    final nextFromList = occurrences.where((occ) => occ.startKst.isAfter(now)).firstOrNull;
    
    if (nextFromList == null && summary.next == null) return true;
    if (nextFromList == null || summary.next == null) return false;
    
    return nextFromList.id == summary.next!.id;
  }

  String _getNextComparison(List<EventOccurrence> occurrences, TodaySummaryData summary) {
    final now = AppTime.nowKst();
    final nextFromList = occurrences.where((occ) => occ.startKst.isAfter(now)).firstOrNull;
    
    if (nextFromList == null && summary.next == null) {
      return 'Both null ✓';
    }
    
    if (nextFromList == null) {
      return 'TL=null, SUM=${summary.next!.title}';
    }
    
    if (summary.next == null) {
      return 'TL=${nextFromList.title}, SUM=null';
    }
    
    if (nextFromList.id == summary.next!.id) {
      return '${nextFromList.title} ✓';
    }
    
    return 'TL=${nextFromList.title}, SUM=${summary.next!.title}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? AppTime.nowKst(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = AppTime.dayStartKst(date);
      });
    }
  }

  void _dumpToConsole(DateKey checkKey) {
    final debugRepo = ref.read(debugRepositoryProvider);
    debugRepo.debugDumpDayKey(checkKey);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug info dumped to console'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}