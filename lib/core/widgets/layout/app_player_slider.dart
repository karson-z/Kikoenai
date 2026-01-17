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

// 引入修改后的源码文件
import '../slider/sllding_up_panel_modify.dart';

class SlidingPlayerPanel extends ConsumerStatefulWidget {
  final double minHeight;
  final double maxHeight;
  final bool isDraggable;
  final Widget body;

  // 注意：由于 MusicPlayerView 内部接管了收起状态的 UI 渲染，
  // 外部传入的 collapsed 参数在此模式下可能不再被使用，或者需要你手动传给 MusicPlayerView
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

    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBarHeight
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    return SlidingUpPanel(
      controller: _panelController,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      isDraggable: widget.isDraggable,

      // 【修改点 1】: 禁用默认淡出，完全交由 MusicPlayerView 内部控制
      fadeCollapsed: false,

      // 【修改点 2】: 这里传 null。
      // 因为 MusicPlayerView 的 Stack 布局里已经包含了“收起状态”的 UI (Layer 2)。
      // 如果这里再传 widget.collapsed，会导致界面上出现两个迷你播放器重叠。
      collapsed: null,

      // 【修改点 3】: 使用 panelBuilder 获取 AnimationController
      panelBuilder: (ScrollController sc, AnimationController controller) {
        return MusicPlayerView(
          // 将 controller 作为进度通知器传下去
          dragProgressNotifier: controller,
          panelController: _panelController,
          // 传入最小高度，用于内部计算 collapsed 状态的位置
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