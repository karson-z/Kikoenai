import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/service/audio/audio_extension.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import '../../../features/player/presentation/page/player_view.dart';
import '../../service/audio/audio_service_media_kit.dart';
import '../common/back_button_interceptor.dart';
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

  //状态记录标志位：假设初始状态是收起的，所以默认为 false

  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _panelController = widget.controller ?? PanelController();
  }

  //  统一的状态拦截与分发方法
  // 任何在展开/收起时需要执行的逻辑都集中在这里处理
  void _handlePanelStateChange(bool isOpen, dynamic mainController) {
    // 核心拦截逻辑：如果新传入的状态与当前记录的状态相同，说明是无效的重复触发，直接丢弃
    if (_isPanelOpen == isOpen) return;

    // 状态发生了实质性改变，更新记录
    _isPanelOpen = isOpen;

    // 根据真实的新状态执行对应的业务逻辑
    if (isOpen) {
      mainController.expandPlayer();
      mainController.setBottomNav(false);
      AudioServiceSingleton.instance.toggleVideoDecoding(true);
    } else {
      mainController.collapsePlayer();
      mainController.setBottomNav(true);
      AudioServiceSingleton.instance.toggleVideoDecoding(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final mainState = ref.watch(mainScaffoldProvider);
    final isMobile = MediaQuery.of(context).size.width < AppConstants.kMobileBreakpoint;

    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBarHeight + 15
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    return BackButtonPriorityWrapper(
      zIndex: 10,
      name: 'MainSlidingPlayer',
      onBack: () {
        if (mainState.isPlayerExpanded) {
          debugPrint("PriorityWrapper: 收起播放器，拦截事件");
          _panelController.close();
          return true;
        }

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
          return PlayerView(
            dragProgressNotifier: controller,
            panelController: _panelController,
            minHeight: widget.minHeight,
          );
        },
        body: Padding(
          padding: EdgeInsets.only(bottom: safePadding),
          child: widget.body,
        ),
        // 【修改】将原本的散装逻辑替换为指向带有状态拦截的方法
        onPanelOpened: () => _handlePanelStateChange(true, mainController),
        onPanelClosed: () => _handlePanelStateChange(false, mainController),
      ),
    );
  }
}