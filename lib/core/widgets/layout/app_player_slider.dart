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
import 'package:back_button_interceptor/back_button_interceptor.dart';
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
  late final PanelController _panelController;

  @override
  void initState() {
    super.initState();
    _panelController = widget.controller ?? PanelController();
    // 2. 注册拦截器 (添加到最前面)
    BackButtonInterceptor.add(_backButtonInterceptor, zIndex: 1, name: 'PlayerPanel');
  }

  @override
  void dispose() {
    // 3. 移除拦截器
    BackButtonInterceptor.remove(_backButtonInterceptor);
    super.dispose();
  }

  bool _backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    final isExpanded = ref.read(mainScaffoldProvider).isPlayerExpanded;

    if (isExpanded) {
      debugPrint("拦截返回键：收起播放器");
      _panelController.close();
      return true;
    }

    return false;
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

    // 5. 移除了 PopScope，因为逻辑已移至拦截器
    return SlidingUpPanel(
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