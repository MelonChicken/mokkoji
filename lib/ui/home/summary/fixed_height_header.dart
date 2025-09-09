import 'package:flutter/material.dart';

/// 설계 요지: SliverPersistentHeader의 높이를 "하나의 고정값"으로 선언하고,
/// child는 SizedBox.expand로 받은 constraints를 그대로 채우게 하여
/// layoutExtent == paintExtent == child height 를 항상 만족시킨다.
class FixedHeightHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  FixedHeightHeader({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child); // ❗ child에 별도 높이 제약 X
  }

  @override
  bool shouldRebuild(covariant FixedHeightHeader oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

/* acceptance
- 이 delegate를 사용할 때 child에 ConstrainedBox(height: ...)를 주지 않는다.
- minExtent == maxExtent == height 이므로 SliverGeometry 불일치가 발생하지 않는다.
*/