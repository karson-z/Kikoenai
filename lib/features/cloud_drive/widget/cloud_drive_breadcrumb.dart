import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';

class CloudDriveBreadcrumb extends StatelessWidget {
  const CloudDriveBreadcrumb({
    super.key,
    required this.segments,
    required this.onHomeTap,
    required this.onSegmentTap,
  });

  final List<String> segments;
  final VoidCallback onHomeTap;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.black : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BreadcrumbBar(
          paths: segments,
          onHomeTap: onHomeTap,
          onPathTap: onSegmentTap,
          backgroundColor: Colors.transparent,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
      ),
    );
  }
}

class CloudDriveBreadcrumbHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  CloudDriveBreadcrumbHeaderDelegate({
    required this.segments,
    required this.onHomeTap,
    required this.onSegmentTap,
    this.height = 64,
  });

  final List<String> segments;
  final VoidCallback onHomeTap;
  final ValueChanged<int> onSegmentTap;
  final double height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: CloudDriveBreadcrumb(
        segments: segments,
        onHomeTap: onHomeTap,
        onSegmentTap: onSegmentTap,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant CloudDriveBreadcrumbHeaderDelegate oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.height != height ||
        oldDelegate.onHomeTap != onHomeTap ||
        oldDelegate.onSegmentTap != onSegmentTap;
  }
}
