import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:name_app/core/widgets/common/global_search_input.dart';
import 'package:name_app/core/widgets/common/collapsible_tab_bar.dart';

class MobileSearchAppBar extends StatelessWidget {
  final double collapsePercent; // 0: 展开, 1: 完全折叠
  final String hintText;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;
  final ValueNotifier<double> collapsePercentNotifier;

  const MobileSearchAppBar({
    Key? key,
    required this.collapsePercent,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
    required this.collapsePercentNotifier,
    this.hintText = '搜索作品...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    const double expandedHeight = 120;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      floating: false,
      expandedHeight: expandedHeight,
      backgroundColor: scaffoldBg,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: CollapsibleTabBar(
          collapsePercentNotifier: collapsePercentNotifier,
          selectedFilter: selectedFilter,
          filters: filters,
          onFilterChanged: onFilterChanged,
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          // 计算折叠百分比：0 完全展开，1 完全折叠
          debugPrint("opacity: $collapsePercent");
          return Padding(
            padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16),
            child: Opacity(
              opacity: (1 - collapsePercent).clamp(0.0, 1.0),
              child: Row(
                children: [
                  Expanded(child: GlobalSearchInput(hintText: hintText)),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
                    icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    onPressed: themeVM.toggleLightDark,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
