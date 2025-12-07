import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme_view_model.dart';
import '../player/player_view.dart';
import '../player/player_list_sheet.dart';

class SlidingPlayerPanel extends ConsumerWidget {
  final double minHeight;
  final double maxHeight;
  final bool isDraggable;
  final Widget body;
  final Widget? collapsed;
  final VoidCallback? onQueuePressed;
  final PanelController? controller;

  const SlidingPlayerPanel({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.body,
    this.collapsed,
    this.isDraggable = true,
    this.onQueuePressed,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelController = controller ?? PanelController();
    final location = GoRouterState.of(context).uri.path;
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final isDark = ref.watch(explicitDarkModeProvider);
    final mainState = ref.watch(mainScaffoldProvider);
    final isMobile = MediaQuery.of(context).size.width < AppConstants.kMobileBreakpoint;
    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location) ? minHeight + AppConstants.kAppBarHeight : minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;
    return SlidingUpPanel(
      controller: panelController,
      minHeight: minHeight,
      maxHeight: maxHeight,
      isDraggable: isDraggable,
      panel:  MusicPlayerView(
        onQueuePressed: () => PlayerPlaylistSheet.show(context,isDark: isDark),
      ),
      collapsed: collapsed,
      body: Padding(
        padding: EdgeInsets.only(bottom: safePadding),
        child: body,
      ),
      onPanelOpened: () {
        mainController.expandPlayer();
        mainController.setBottomNav(false);
      },
      onPanelClosed: () {
        mainController.collapsePlayer();
        mainController.setBottomNav(true);
      },
    );
  }
}
