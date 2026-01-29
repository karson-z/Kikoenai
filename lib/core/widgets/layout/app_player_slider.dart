import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme_view_model.dart';
import '../player/player_view.dart';
import '../player/player_list_sheet.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import '../slider/sllding_up_panel_modify.dart';

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
    BackButtonInterceptor.add(_backButtonInterceptor, zIndex: 1, name: 'PlayerPanel');
  }

  @override
  void dispose() {
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
    // 优化边界，让floatingButton 在任何设备上都能显示完全
    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBarHeight + 15
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    return SlidingUpPanel(
      controller: _panelController,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      isDraggable: widget.isDraggable,
      // 禁用淡入淡出, 基于源码修改
      fadeCollapsed: false,
      panelBuilder: (ScrollController sc, AnimationController controller) {
        return MusicPlayerView(
          dragProgressNotifier: controller,
          panelController: _panelController,
          minHeight: widget.minHeight,
          onQueuePressed: () => PlayerPlaylistSheet.show(context, isDark: isDark),
        );
      },

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