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
    return SliverPersistentHeader(
      pinned: false,
      delegate: _MobileSearchHeaderDelegate(
        collapsePercent: collapsePercent,
        hintText: hintText,
      ),
    );
  }
}

class _MobileSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double collapsePercent;
  final String hintText;

  _MobileSearchHeaderDelegate({
    required this.collapsePercent,
    required this.hintText,
  });

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 透明度动画
    final opacity = (1 - collapsePercent).clamp(0.0, 1.0);

    // AnimatedBuilder 监听 Theme 的变化
    return AnimatedBuilder(
      animation: Listenable.merge(
          [Provider.of<ThemeViewModel>(context, listen: true)]),
      builder: (context, _) {
        final themeVM = context.watch<ThemeViewModel>();
        final isDark = themeVM.themeMode == ThemeMode.dark;
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

        return Container(
          color: scaffoldBg,
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
                  height: 45, // 高度固定
                  child: GlobalSearchInput(hintText: hintText),
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
    );
  }

  @override
  bool shouldRebuild(covariant _MobileSearchHeaderDelegate oldDelegate) {
    // 只关心 collapsePercent 和 hintText
    return oldDelegate.collapsePercent != collapsePercent ||
        oldDelegate.hintText != hintText;
  }
}
