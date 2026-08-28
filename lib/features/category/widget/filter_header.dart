import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/collapsible_tab_bar.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class FilterHeader extends StatelessWidget {
  const FilterHeader({
    super.key,
    required this.height,
    required this.tabController,
    required this.sortOrders,
    required this.sortDirection,
    required this.hasSubtitles,
    required this.onSortTap,
    required this.onSubtitleTap,
    required this.filterRow,
  });

  final double height;
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

    return SizedBox(
      height: height,
      child: ColoredBox(
        color: isDark ? Colors.black : Colors.white,
        child: Column(
          children: [
            CollapsibleTabBar(
              controller: tabController,
              sortDirection: sortDirection,
              hasSubtitles: hasSubtitles,
              filters: sortOrders.map((order) => order.label).toList(),
              onSortTap: onSortTap,
              onSubtitleTap: onSubtitleTap,
            ),
            Expanded(child: filterRow),
          ],
        ),
      ),
    );
  }
}
