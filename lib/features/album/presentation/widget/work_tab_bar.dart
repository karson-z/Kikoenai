import 'package:flutter/material.dart';
import 'package:name_app/core/widgets/common/collapsible_tab_bar.dart';

class TabBarDelegateWrapper extends SliverPersistentHeaderDelegate {
  final double collapsePercent;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  TabBarDelegateWrapper({
    required this.collapsePercent,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CollapsibleTabBar(
      collapsePercent: collapsePercent,
      selectedFilter: selectedFilter,
      filters: filters,
      onFilterChanged: onFilterChanged,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarDelegateWrapper oldDelegate) =>
      oldDelegate.collapsePercent != collapsePercent ||
      oldDelegate.selectedFilter != selectedFilter;
}
