import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';

import 'package:window_manager/window_manager.dart';

import 'package:kikoenai/core/widgets/common/global_search_input.dart';

import 'package:kikoenai/core/widgets/common/theme_toggle_button.dart';

import 'package:kikoenai/core/widgets/common/win_control_button.dart';

import '../../theme/app_layout_tokens.dart';

PreferredSizeWidget buildAdaptiveAppBar(
  BuildContext context, {

  Widget? title,

  List<Widget>? actions,

  bool automaticallyImplyLeading = true,

  double? height = kToolbarHeight,
  bool includeWindowControls = true,
}) {
  final theme = Theme.of(context);

  if (!includeWindowControls ||
      kIsWeb ||
      defaultTargetPlatform != TargetPlatform.windows) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height ?? kToolbarHeight),

      child: AppBar(
        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        automaticallyImplyLeading: automaticallyImplyLeading,

        toolbarHeight: height,

        titleSpacing: 0,

        title: Padding(
          padding: context.layout.pagePadding(),

          child: Row(
            children: [
              if (title != null)
                Expanded(
                  child: DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title,
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: GlobalSearchInput(
                    hintText: '搜索作品、作者或标签…',
                    height: 44,
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ),
              ),
              const ThemeToggleButton(),

              if (actions != null) ...actions,
            ],
          ),
        ),
      ),
    );
  }

  return PreferredSize(
    preferredSize: Size.fromHeight(height ?? kToolbarHeight),

    child: Container(
      height: height ?? kToolbarHeight,

      color: theme.appBarTheme.backgroundColor ?? Colors.transparent,

      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  children: [
                    if (automaticallyImplyLeading) const BackButton(),

                    if (title != null)
                      Flexible(
                        child: DefaultTextStyle(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                theme.appBarTheme.foregroundColor ??
                                theme.colorScheme.onSurface,

                            fontSize: 20,

                            fontWeight: FontWeight.w600,
                          ),

                          child: title,
                        ),
                      ),

                    const Spacer(),

                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
          ),

          const WindowControlButtons(),
        ],
      ),
    ),
  );
}
