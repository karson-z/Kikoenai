import 'package:flutter/material.dart';
import 'package:name_app/core/widgets/common/global_search_input.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:provider/provider.dart';

class MobileSearchAppBar extends StatelessWidget {
  final double collapsePercent; // 0: 展开, 1: 完全折叠
  final String hintText;

  const MobileSearchAppBar({
    Key? key,
    required this.collapsePercent,
    this.hintText = '搜索作品...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      expandedHeight: 80,
      backgroundColor: scaffoldBg,
      foregroundColor: scaffoldBg,
      elevation: 0.5,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 透明度动画
          final double opacity = (1 - collapsePercent).clamp(0.0, 1.0);

          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
            ),
            child: Opacity(
              opacity: opacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 255,
                    height: 45, // 固定高度
                    child: GlobalSearchInput(
                      hintText: hintText,
                    ),
                  ),
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
