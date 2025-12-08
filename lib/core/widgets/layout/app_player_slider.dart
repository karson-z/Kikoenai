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

// 1. 改为 ConsumerStatefulWidget 以便管理状态
class SlidingPlayerPanel extends ConsumerStatefulWidget {
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
  ConsumerState<SlidingPlayerPanel> createState() => _SlidingPlayerPanelState();
}

class _SlidingPlayerPanelState extends ConsumerState<SlidingPlayerPanel> {
  // 内部持有一个 Controller，如果外部没传就用这个，外部传了就用外部的
  late final PanelController _panelController;

  @override
  void initState() {
    super.initState();
    _panelController = widget.controller ?? PanelController();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final isDark = ref.watch(explicitDarkModeProvider);
    final mainState = ref.watch(mainScaffoldProvider);
    final isMobile = MediaQuery.of(context).size.width < AppConstants.kMobileBreakpoint;

    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBarHeight
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    // 3. 使用 PopScope 拦截返回事件
    return PopScope(
      // 如果面板是打开的，canPop 为false(拦截)；否则为 true (放行)
      canPop: !mainState.isPlayerExpanded,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          // 如果系统已经处理了返回（canPop为true时），我们什么都不做
          return;
        }
        // 如果被拦截了（canPop为false），说明面板是开着的，我们手动关闭它
        if (mainState.isPlayerExpanded) {
          debugPrint("退出播放器");
          _panelController.close();
          // 注意：这里不需要手动 setState，因为 close() 动画完成后会触发 onPanelClosed
        }
      },
      child: SlidingUpPanel(
        controller: _panelController,
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
        isDraggable: widget.isDraggable,
        panel: MusicPlayerView(
          onQueuePressed: () => PlayerPlaylistSheet.show(context, isDark: isDark),
        ),
        collapsed: widget.collapsed,
        body: Padding(
          padding: EdgeInsets.only(bottom: safePadding),
          child: widget.body,
        ),
        onPanelOpened: () {
          // 4. 更新状态为打开
          mainController.expandPlayer();
          mainController.setBottomNav(false);
        },
        onPanelClosed: () {
          // 5. 更新状态为关闭
          mainController.collapsePlayer();
          mainController.setBottomNav(true);
        },
      ),
    );
  }
}