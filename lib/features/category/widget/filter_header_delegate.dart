import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../core/widgets/common/collapsible_tab_bar.dart';

class FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final double pinnedHeight;
  final List<SortOrder> sortOrders;
  final SortDirection sortDirection;
  final bool hasSubtitles;
  final VoidCallback onSortTap;
  final VoidCallback onSubtitleTap;
  final Widget filterRowWidget;

  FilterHeaderDelegate({
    required this.tabController,
    required this.pinnedHeight,
    required this.sortOrders,
    required this.sortDirection,
    required this.hasSubtitles,
    required this.onSortTap,
    required this.onSubtitleTap,
    required this.filterRowWidget,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : Colors.white;

    return Container(
      color: bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. TabBar 部分
          CollapsibleTabBar(
            controller: tabController,
            sortDirection: sortDirection,
            hasSubtitles: hasSubtitles,
            filters: sortOrders.map((e) => e.label).toList(),
            onSortTap: onSortTap,
            onSubtitleTap: onSubtitleTap,
          ),

          // 2. Filter Row 部分 (直接渲染父组件传进来的 Widget)
          Expanded(
            child: filterRowWidget,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => pinnedHeight;

  @override
  double get minExtent => pinnedHeight;

  @override
  bool shouldRebuild(covariant FilterHeaderDelegate oldDelegate) {
    // 只要核心状态或传入的 Widget 发生变化，就触发重绘
    return oldDelegate.sortDirection != sortDirection ||
        oldDelegate.hasSubtitles != hasSubtitles ||
        oldDelegate.filterRowWidget != filterRowWidget;
  }
}