import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
import 'package:kikoenai/core/widgets/common/global_search_input.dart';
import '../../theme/theme_view_model.dart';

class MobileSearchAppBar extends ConsumerWidget {
  static const double toolbarHeight = 64;

  final String hintText;
  final VoidCallback? onSearchTap;
  final String title;

  const MobileSearchAppBar({
    Key? key,
    this.hintText = '搜索作品...',
    this.onSearchTap,
    this.title = '首页',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    final layout = context.layout;
    final openSearch = onSearchTap ?? () => context.push(AppRoutes.search);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: layout.searchToolbarHeight,
        child: Padding(
          padding: layout.pagePadding(),
          child: Row(
            children: [
              if (layout.isPhoneLandscape) ...[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '搜索作品',
                  onPressed: openSearch,
                  icon: const Icon(Icons.search),
                ),
              ] else
                Expanded(
                  child: GlobalSearchInput(
                    hintText: hintText,
                    height: 44,
                    onTap: openSearch,
                  ),
                ),
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
      ),
    );
  }
}
