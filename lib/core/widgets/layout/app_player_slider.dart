import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../player/player_view.dart';
import '../player/player_mini_bar.dart';
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
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    return SlidingUpPanel(
      controller: panelController,
      minHeight: minHeight,
      maxHeight: maxHeight,
      isDraggable: isDraggable,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      panel: Stack(
        children: [
          MusicPlayerView(
            onQueuePressed: () => PlayerPlaylistSheet.show(context),
          ),
        ],
      ),
      collapsed: collapsed,
      body: body,
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
