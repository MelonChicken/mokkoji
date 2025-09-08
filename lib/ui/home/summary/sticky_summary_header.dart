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
  double get minExtent => _computeExtent(minHeight);

  @override
  double get maxExtent => _computeExtent(maxHeightCap);

  double _computeExtent(double fallback) {
    return fallback.clamp(minHeight, maxHeightCap);
  }

  double _measureRequiredHeight(BuildContext context, double maxWidth) {
    if (heightMeasurer != null) {
      return heightMeasurer!(context, maxWidth);
    }
    return minHeight;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final maxWidth = MediaQuery.of(context).size.width;
    final requiredHeight = _measureRequiredHeight(context, maxWidth);
    final actualHeight = requiredHeight.clamp(minHeight, maxHeightCap);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: actualHeight,
        width: maxWidth,
        child: childBuilder(context, maxWidth),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}