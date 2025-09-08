import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mokkoji/ui/home/summary/today_summary_card.dart';
import 'package:mokkoji/ui/home/summary/sticky_summary_header.dart';
import 'package:mokkoji/ui/home/timeline/day_timeline_view.dart';
import 'package:mokkoji/data/models/today_summary_data.dart';
import 'package:mokkoji/core/time/app_time.dart';
import 'package:mokkoji/theme/app_theme.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await AppTime.ensureInitialized();
  });

  group('Summary Overflow Prevention Tests', () {
    testWidgets('Card adapts to large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(300, 600),
                textScaler: TextScaler.linear(1.3), // Large text scale
              ),
              child: TodaySummaryCard(
                data: TodaySummaryData(
                  count: 3,
                  next: EventOccurrence(
                    startTime: DateTime.now().add(const Duration(hours: 1)),
                    title: '매우 긴 일정 제목이 있는 중요한 회의입니다',
                    sourcePlatform: 'google',
                    location: '매우 긴 장소명을 가진 장소입니다',
                  ),
                  lastSyncAt: DateTime.now(),
                  offline: true,
                ),
                onViewDetails: () {},
                onJumpToNow: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for RenderFlex overflow errors
      expect(tester.takeException(), isNull);
      
      // Verify text is properly ellipsized
      final titleFinder = find.text('매우 긴 일정 제목이 있는 중요한 회의입니다');
      expect(titleFinder, findsOneWidget);
      
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.overflow, TextOverflow.ellipsis);
      expect(titleWidget.maxLines, 1);
    });

    testWidgets('Card works on narrow screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 600), // Very narrow screen
              ),
              child: TodaySummaryCard(
                data: TodaySummaryData(
                  count: 5,
                  next: EventOccurrence(
                    startTime: DateTime.now().add(const Duration(hours: 2)),
                    title: '긴 제목',
                    sourcePlatform: 'kakao',
                    location: '긴 장소명',
                  ),
                  lastSyncAt: DateTime.now(),
                  offline: false,
                ),
                onViewDetails: () {},
                onJumpToNow: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No overflow errors expected
      expect(tester.takeException(), isNull);
      
      // Buttons should wrap properly
      expect(find.text('자세히'), findsOneWidget);
      expect(find.text('지금으로'), findsOneWidget);
    });

    testWidgets('Sticky header maintains fixed height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickySummaryHeader(
                    minHeight: 120,
                    maxHeightCap: 180,
                    childBuilder: (context, maxWidth) {
                      return TodaySummaryCard(
                        data: TodaySummaryData(
                          count: 2,
                          next: null,
                          lastSyncAt: DateTime.now(),
                          offline: false,
                        ),
                        onViewDetails: () {},
                        onJumpToNow: () {},
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 1000),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the summary card initially
      expect(find.text('오늘의 일정 2건'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Header should still be visible (pinned)
      expect(find.text('오늘의 일정 2건'), findsOneWidget);
    });
  });

  group('KST Time Handling Tests', () {
    test('AppTime returns KST timezone', () {
      final now = AppTime.nowKst();
      
      // KST should be GMT+9 or show as KST
      final formatter = DateFormat('z');
      final timezone = formatter.format(now);
      expect(timezone, anyOf(contains('GMT+9'), contains('KST'), contains('+09')));
    });

    test('Minutes from midnight calculation is accurate', () {
      final testTime = DateTime(2024, 1, 1, 14, 30); // 2:30 PM
      final minutes = AppTime.minutesFromMidnightKst(testTime);
      
      expect(minutes, 14 * 60 + 30); // 870 minutes
    });

    test('Same day KST comparison works correctly', () {
      final date1 = DateTime(2024, 1, 1, 23, 59);
      final date2 = DateTime(2024, 1, 2, 0, 1);
      
      expect(AppTime.isSameDayKst(date1, date1), isTrue);
      expect(AppTime.isSameDayKst(date1, date2), isFalse);
    });

    testWidgets('Timeline shows current time in KST', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: DayTimelineView(
                date: DateTime.now(),
                events: const [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final now = AppTime.nowKst();
      final expectedTimeLabel = DateFormat('HH:mm', 'ko_KR').format(now);
      
      // Should find current time label somewhere in the timeline
      expect(find.textContaining(expectedTimeLabel), findsWidgets);
    });
  });

  group('Contrast and Accessibility Tests', () {
    testWidgets('Light theme maintains proper contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TodaySummaryCard(
              data: TodaySummaryData(
                count: 3,
                next: null,
                lastSyncAt: DateTime.now(),
                offline: false,
              ),
              onViewDetails: () {},
              onJumpToNow: () {},
            ),
          ),
        ),
      );

      final cs = AppTheme.lightTheme.colorScheme;
      
      // Verify contrast ratios meet WCAG AA standard (4.5:1)
      expect(_calculateContrastRatio(cs.onPrimaryContainer, cs.primaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(cs.onSurface, cs.surface),
          greaterThanOrEqualTo(4.5));
    });

    testWidgets('Dark theme maintains proper contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TodaySummaryCard(
              data: TodaySummaryData(
                count: 3,
                next: null,
                lastSyncAt: DateTime.now(),
                offline: false,
              ),
              onViewDetails: () {},
              onJumpToNow: () {},
            ),
          ),
        ),
      );

      final cs = AppTheme.darkTheme.colorScheme;
      
      // Verify contrast ratios meet WCAG AA standard (4.5:1)
      expect(_calculateContrastRatio(cs.onSurface, cs.surfaceContainerHighest),
          greaterThanOrEqualTo(4.5));
    });
  });
}

double _calculateContrastRatio(Color foreground, Color background) {
  final fgLuminance = _relativeLuminance(foreground);
  final bgLuminance = _relativeLuminance(background);
  
  final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
  final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
  
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  final r = _gammaCorrect(color.red / 255.0);
  final g = _gammaCorrect(color.green / 255.0);
  final b = _gammaCorrect(color.blue / 255.0);
  
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _gammaCorrect(double colorChannel) {
  if (colorChannel <= 0.03928) {
    return colorChannel / 12.92;
  } else {
    return ((colorChannel + 0.055) / 1.055) * ((colorChannel + 0.055) / 1.055);
  }
}