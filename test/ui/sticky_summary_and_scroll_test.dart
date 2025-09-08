import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mokkoji/ui/home/home_screen.dart';
import 'package:mokkoji/ui/home/today_summary_card.dart';
import 'package:mokkoji/ui/home/timeline/day_timeline_view.dart';
import 'package:mokkoji/data/models/today_summary_data.dart';
import 'package:mokkoji/theme/app_theme.dart';

void main() {
  group('Sticky Summary and Scroll Tests', () {
    testWidgets('Summary card remains sticky when scrolling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TestStickyHeaderDelegate(
                    height: 180,
                    child: TodaySummaryCard(
                      data: TodaySummaryData(
                        count: 5,
                        next: null,
                        lastSyncAt: DateTime(2024, 1, 1, 12, 0),
                        offline: false,
                      ),
                      onViewDetails: () {},
                      onJumpToNow: () {},
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 2000),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('오늘의 일정 5건'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 일정 5건'), findsOneWidget);
    });

    testWidgets('Timeline scrolls to current time on initial load', (tester) async {
      final controller = ScrollController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: DayTimelineView(
                date: DateTime.now(),
                events: const [],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedMinutes = now.hour * 60 + now.minute;
      const hourHeight = 80.0;
      final pixelsPerMinute = hourHeight / 60.0;
      const anchor = 0.3;
      
      final expectedOffset = (expectedMinutes * pixelsPerMinute - 600 * anchor)
          .clamp(0.0, double.infinity);

      expect(controller.offset, closeTo(expectedOffset, 50.0));
    });

    testWidgets('Jump to now button scrolls to current time', (tester) async {
      final controller = ScrollController();
      late DayTimelineView timelineView;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                timelineView = DayTimelineView(
                  date: DateTime.now(),
                  events: const [],
                  controller: controller,
                );
                return SizedBox(
                  height: 600,
                  child: timelineView,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);

      timelineView.jumpToNow();
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
    });

    testWidgets('Current time line is visible for today', (tester) async {
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

      expect(find.byType(Container), findsWidgets);
      
      final currentTimeContainers = tester.widgetList<Container>(
        find.byType(Container),
      ).where((container) {
        return container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).color ==
                ThemeData().colorScheme.error;
      });

      expect(currentTimeContainers.length, greaterThan(0));
    });

    testWidgets('Current time line is not visible for past dates', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: DayTimelineView(
                date: yesterday,
                events: const [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final currentTimeContainers = tester.widgetList<Container>(
        find.byType(Container),
      ).where((container) {
        return container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).color ==
                ThemeData().colorScheme.error;
      });

      expect(currentTimeContainers.length, 0);
    });
  });

  group('Contrast Tests', () {
    testWidgets('Light theme meets contrast requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TodaySummaryCard(
            data: TodaySummaryData(
              count: 3,
              next: null,
              lastSyncAt: DateTime(2024, 1, 1),
              offline: false,
            ),
            onViewDetails: () {},
            onJumpToNow: () {},
          ),
        ),
      );

      final cs = AppTheme.lightTheme.colorScheme;
      
      expect(_calculateContrastRatio(cs.onPrimaryContainer, cs.primaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(cs.onSurface, cs.surface),
          greaterThanOrEqualTo(4.5));
    });

    testWidgets('Dark theme meets contrast requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TodaySummaryCard(
            data: TodaySummaryData(
              count: 3,
              next: null,
              lastSyncAt: DateTime(2024, 1, 1),
              offline: false,
            ),
            onViewDetails: () {},
            onJumpToNow: () {},
          ),
        ),
      );

      final cs = AppTheme.darkTheme.colorScheme;
      
      expect(_calculateContrastRatio(cs.onPrimaryContainer, cs.primaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(cs.onSurface, cs.surface),
          greaterThanOrEqualTo(4.5));
    });
  });
}

class _TestStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _TestStickyHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
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