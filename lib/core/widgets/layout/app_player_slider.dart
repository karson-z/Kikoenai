import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 必须引入，用于 SystemNavigator.pop
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 请根据你的实际路径引入 BackButtonPriorityWrapper
// import 'package:kikoenai/core/widgets/common/back_button_priority_wrapper.dart';
import '../../theme/theme_view_model.dart';
import '../common/back_button_interceptor.dart';
import '../player/player_view.dart';
import '../player/player_list_sheet.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final isDark = ref.watch(explicitDarkModeProvider);
    final mainState = ref.watch(mainScaffoldProvider);
    final isMobile = MediaQuery.of(context).size.width < AppConstants.kMobileBreakpoint;

    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBarHeight + 15
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    return BackButtonPriorityWrapper(
      // 必须小于 PlayerPlaylistSheet 的 100，否则弹窗无法优先关闭。
      // 必须大于默认值 0，确保拦截系统默认返回。
      zIndex: 10,
      name: 'MainSlidingPlayer',
      onBack: () {
        // 1. 如果播放器展开，拦截并收起
        if (mainState.isPlayerExpanded) {
          debugPrint("PriorityWrapper: 收起播放器，拦截事件");
          _panelController.close();
          return true;
        }

        // 2. 如果播放器没展开，不拦截
        debugPrint("PriorityWrapper: 放行，交由系统路由处理");
        return false;
      },

      child: SlidingUpPanel(
        controller: _panelController,
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
        isDraggable: widget.isDraggable,
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
      ),
    );
  }
}