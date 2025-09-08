import 'package:flutter/material.dart';

/// 동적 높이 측정이 가능한 Sticky Header Delegate
class StickySummaryHeader extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeightCap;
  final Widget Function(BuildContext context, double maxWidth) childBuilder;
  final double Function(BuildContext context, double maxWidth)? heightMeasurer;

  StickySummaryHeader({
    required this.minHeight,
    required this.maxHeightCap,
    required this.childBuilder,
    this.heightMeasurer,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeightCap;

  double _getActualMaxHeight(BuildContext context, double maxWidth) {
    if (heightMeasurer != null) {
      final measuredHeight = heightMeasurer!(context, maxWidth);
      // Always cap at maxHeightCap to prevent geometry violations
      return measuredHeight.clamp(minHeight, maxHeightCap);
    }
    return maxHeightCap;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final maxWidth = MediaQuery.of(context).size.width;
    
    // Get the actual desired height (capped appropriately)
    final actualMaxHeight = _getActualMaxHeight(context, maxWidth);
    
    // Calculate current extent considering shrink offset
    final currentExtent = (actualMaxHeight - shrinkOffset).clamp(minExtent, actualMaxHeight);

    return SizedBox(
      height: currentExtent,
      width: maxWidth,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: childBuilder(context, maxWidth),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}