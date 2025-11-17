import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/widgets/common/global_search_input.dart';
import '../../theme/theme_view_model.dart';

class MobileSearchAppBar extends ConsumerWidget {
  final ValueNotifier<double> collapsePercentNotifier;
  final String hintText;
  final Widget? bottom;
  const MobileSearchAppBar({
    Key? key,
    required this.collapsePercentNotifier,
    this.bottom,
    this.hintText = '搜索作品...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 ThemeNotifier
    final themeStateAsync = ref.watch(themeNotifierProvider);

    final themeMode = themeStateAsync.maybeWhen(
      data: (value) => value.mode,
      orElse: () => ThemeMode.system,
    );

    final isDark = themeMode == ThemeMode.dark;
    final hasBottom = bottom == null;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    double expandedHeight = 120;
    expandedHeight = hasBottom ? expandedHeight - 40 : expandedHeight;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      floating: hasBottom,
      snap: false,
      expandedHeight: expandedHeight,
      backgroundColor: scaffoldBg,
      bottom: PreferredSize(
        preferredSize: hasBottom
            ? const Size.fromHeight(80)
            : const Size.fromHeight(10),
        child: bottom ?? const SizedBox.shrink(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;

          return ValueListenableBuilder<double>(
            valueListenable: collapsePercentNotifier, // <-- 直接用 collapsePercentNotifier
            builder: (_, collapsePercent, __) {
              collapsePercent = collapsePercent.clamp(0.0, 1.0);
              debugPrint("collapsePercent: $collapsePercent");
              return Padding(
                padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16),
                child: Opacity(
                  opacity: hasBottom ? 1 : (1 - collapsePercent).clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      Expanded(child: GlobalSearchInput(hintText: hintText)),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
                        icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                        onPressed: () {
                          ref.read(themeNotifierProvider.notifier).toggleLightDark();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
