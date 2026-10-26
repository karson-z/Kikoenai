import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';

/// Narrow layouts expose global search beside the page's own controls.
class PageGlobalSearchButton extends StatelessWidget {
  const PageGlobalSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.layout.useWideNavigation) return const SizedBox.shrink();
    return SizedBox(
      width: 36,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: '全局搜索',
        onPressed: () => context.push(AppRoutes.search),
        icon: const Icon(Icons.search),
      ),
    );
  }
}
