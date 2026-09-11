import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/collapsible_tab_bar.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 排序 Tab 栏 + 筛选行的组合头部。
/// 高度自适应：筛选行收起时为单行横条，展开时随筛选区一起撑开。
class FilterHeader extends StatelessWidget {
  const FilterHeader({
    super.key,
    required this.tabController,
    required this.sortOrders,
    required this.sortDirection,
    required this.hasSubtitles,
    required this.onSortTap,
    required this.onSubtitleTap,
    required this.filterRow,
  });

  final TabController tabController;
  final List<SortOrder> sortOrders;
  final SortDirection sortDirection;
  final bool hasSubtitles;
  final VoidCallback onSortTap;
  final VoidCallback onSubtitleTap;
  final Widget filterRow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? Colors.black : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CollapsibleTabBar(
            controller: tabController,
            sortDirection: sortDirection,
            hasSubtitles: hasSubtitles,
            filters: sortOrders.map((order) => order.label).toList(),
            onSortTap: onSortTap,
            onSubtitleTap: onSubtitleTap,
          ),
          filterRow,
        ],
      ),
    );
  }
}
