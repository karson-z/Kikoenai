import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/global_search_input.dart';
import '../../theme/theme_view_model.dart';

class MobileSearchAppBar extends ConsumerWidget {
  final String hintText;
  final VoidCallback? onSearchTap;

  const MobileSearchAppBar({
    Key? key,
    this.hintText = '搜索作品...',
    this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final topPadding = MediaQuery.of(context).padding.top;
        return Padding(
          padding: EdgeInsets.only(
              top: topPadding + 16,
              left: 16,
              right: 16,
              bottom: 16
          ),
          child: Row(
            children: [
              Expanded(
                child: GlobalSearchInput(
                  hintText: hintText,
                  onTap: onSearchTap,
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
        );
      },
    );
  }
}