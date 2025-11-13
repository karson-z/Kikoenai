import 'package:flutter/material.dart';
import 'package:name_app/core/widgets/common/collapsible_tab_bar.dart';

import 'package:flutter/material.dart';
import 'package:name_app/core/widgets/common/collapsible_tab_bar.dart';

class TabBarDelegateWrapper extends SliverPersistentHeaderDelegate {
  final ValueNotifier<double> collapsePercentNotifier; // 改成 ValueNotifier
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  TabBarDelegateWrapper({
    required this.collapsePercentNotifier,
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
      collapsePercentNotifier: collapsePercentNotifier, // 传入 ValueNotifier
      selectedFilter: selectedFilter,
      filters: filters,
      onFilterChanged: onFilterChanged,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarDelegateWrapper oldDelegate) =>
      oldDelegate.selectedFilter != selectedFilter ||
      oldDelegate.filters != filters;
}
