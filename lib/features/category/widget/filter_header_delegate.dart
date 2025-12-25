import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../core/enums/sort_options.dart';
import '../../../core/widgets/common/collapsible_tab_bar.dart';
import '../presentation/viewmodel/provider/category_data_provider.dart';
import '../presentation/viewmodel/state/category_ui_state.dart';

class FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final WidgetRef ref; // 传入 ref 以便访问 Provider
  final double pinnedHeight;
  final AutoScrollController scrollController;

  // 传入构建UI所需的回调或参数
  final List<SortOrder> sortOrders;
  final CategoryUiState uiState;
  final CategoryUiNotifier uiNotifier;
  final int totalCount;
  final Function(CategoryUiState, CategoryUiNotifier, int, Color, Color, Color, Color, Color, AutoScrollController) buildFilterRow;

  FilterHeaderDelegate({
    required this.scrollController,
    required this.tabController,
    required this.ref,
    required this.pinnedHeight,
    required this.sortOrders,
    required this.uiState,
    required this.uiNotifier,
    required this.totalCount,
    required this.buildFilterRow,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 重新获取颜色 (Delegate build 时 context 是最新的)
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final Color primaryColor = theme.colorScheme.primary;

    return Container(
      color: bgColor, // 确保背景不透明，防止列表内容滚动上来时看到
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. TabBar 部分
          CollapsibleTabBar(
            controller: tabController,
            sortDirection: uiState.sortDirection,
            hasSubtitles: uiState.subtitleFilter == 0 ? false : true, // 假设你的 State 里有这个字段
            filters: sortOrders.map((e) => e.label).toList(),
            onSortTap: () {
              final next = uiState.sortDirection == SortDirection.asc
                  ? SortDirection.desc
                  : SortDirection.asc;
              uiNotifier.setSort(sortDec: next, refreshData: true);
            },
            onSubtitleTap: () {
              // 触发 Provider 更新状态
              ref.read(categoryUiProvider.notifier).setSubtitleFilter(uiState.subtitleFilter == 0 ? 1 : 0, refreshData: true);
            },
          ),

          // 2. Filter Row 部分 (复用你原来的构建逻辑)
          Expanded(
            child: buildFilterRow(
                uiState, uiNotifier, totalCount,
                bgColor, textColor, subTextColor, fillColor, primaryColor,
                scrollController
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => pinnedHeight;

  @override
  double get minExtent => pinnedHeight; // 保持固定高度

  @override
  bool shouldRebuild(covariant FilterHeaderDelegate oldDelegate) {
    // 当状态改变时重建
    return oldDelegate.uiState != uiState ||
        oldDelegate.totalCount != totalCount;
  }
}