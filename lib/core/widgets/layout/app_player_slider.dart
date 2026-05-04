import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/service/audio/audio_extension.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/player/presentation/page/player_view.dart';
import '../../../features/player/presentation/provider/player_controller_provider.dart';
import '../../service/audio/audio_service_ctrl.dart';
import '../../service/audio/audio_service_media_kit.dart';
import '../common/back_button_interceptor.dart';
import '../slider/sllding_up_panel_modify.dart';


class SlidingPlayerPanel extends ConsumerStatefulWidget {
  final double minHeight;
  final double maxHeight;
  final Widget body;
  final Widget? collapsed;
  final VoidCallback? onQueuePressed;

  const SlidingPlayerPanel({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.body,
    this.collapsed,
    this.onQueuePressed,
  });

  @override
  ConsumerState<SlidingPlayerPanel> createState() => _SlidingPlayerPanelState();
}

class _SlidingPlayerPanelState extends ConsumerState<SlidingPlayerPanel> {
  bool isPanelOpen = false;
  void _handlePanelStateChange(bool isOpen, dynamic mainController) {
    if (isPanelOpen == isOpen) return;
    final isPlaying = ref.read(playerControllerProvider.select((p) => p.playing));
    final portrait = ref.read(playerControllerProvider.select((p) => p.isVideoPortrait));
    final isFullScreen = ref.read(mainScaffoldProvider.select((p) => p.isFullScreen));
    isPanelOpen = isOpen;

    if (isOpen) {
      mainController.expandPlayer();
      mainController.setBottomNav(false);
      if(isPlaying){
        AudioServiceSingleton.instance.toggleVideoDecoding(true);
      }
      if(isFullScreen){
        DisplayUtils.enterFullScreen(portrait);
      }
    } else {
      mainController.collapsePlayer();
      mainController.setBottomNav(true);
      if(isPlaying){
        AudioServiceSingleton.instance.toggleVideoDecoding(false);
      }
      if(isFullScreen){
        DisplayUtils.exitFullScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final mainState = ref.watch(mainScaffoldProvider);
    final isCurrentVideoView = ref.watch(playerControllerProvider.select((p) => p.isCurrentVideoView));
    final panelController = ref.watch(panelControllerProvider);

    final isMobile = MediaQuery.of(context).size.width < AppConstants.kMobileBreakpoint;

    final paddingHeight = mainState.showBottomNav && !OtherUtil.isFullScreenPage(location)
        ? widget.minHeight + AppConstants.kAppBottomNavHeight
        : widget.minHeight;
    final safePadding = isMobile ? paddingHeight : 0.0;

    return BackButtonPriorityWrapper(
      zIndex: 10,
      name: 'MainSlidingPlayer',
      onBack: () {
        if (mainState.isPlayerExpanded) {
          debugPrint("PriorityWrapper: 收起播放器，拦截事件");
          panelController.close();
          return true;
        }

        debugPrint("PriorityWrapper: 放行，交由系统路由处理");
        return false;
      },
      child: SlidingUpPanel(
        controller: panelController,
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
        isDraggable: !isCurrentVideoView || !isPanelOpen,
        fadeCollapsed: false,
        panelBuilder: (ScrollController sc, AnimationController controller) {
          return PlayerView(
            dragProgressNotifier: controller,
            minHeight: widget.minHeight,
          );
        },
        body: Padding(
          padding: EdgeInsets.only(bottom: safePadding),
          child: widget.body,
        ),
        onPanelOpened: () => _handlePanelStateChange(true, mainController),
        onPanelClosed: () => _handlePanelStateChange(false, mainController),
      ),
    );
  }
}