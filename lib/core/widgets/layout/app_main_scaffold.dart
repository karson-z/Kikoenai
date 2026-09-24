import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart'
    show mainScaffoldProvider;
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/widgets/layout/navigation_rail.dart';
import 'package:kikoenai/core/widgets/layout/adaptive_app_bar.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_presentation_controller.dart';
import 'package:kikoenai/features/player/widget/video/video_floating_overlay.dart';
import '../../../features/player/page/player_view.dart';
import '../common/back_button_interceptor.dart';
import '../slider/player_sheet_panel.dart';

final panelControllerProvider = Provider((ref) => PanelController());

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late final VideoPresentationController _videoPresentationController;
  bool _lastIsVideo = false;

  @override
  void initState() {
    super.initState();
    _videoPresentationController = VideoPresentationController(vsync: this);
  }

  @override
  void dispose() {
    _videoPresentationController.dispose();
    super.dispose();
  }

  void _navigateTo(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(visibleDestinationsProvider);
    final int selectedBranchIndex = widget.navigationShell.currentIndex;
    final visibleSelectedIndex = destinations.indexWhere(
      (item) => item.branchIndex == selectedBranchIndex,
    );
    final selectedIndex = visibleSelectedIndex < 0 ? 0 : visibleSelectedIndex;
    final NavigationItem? selectedItem = appNavigationItems
        .where((item) => item.branchIndex == selectedBranchIndex)
        .firstOrNull;
    final String title = selectedItem?.label ?? '';
    final bool isMobile = context.isMobile;
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool showBottomNav = AppRoutes.mainPages.contains(currentPath);
    // NavigationBar owns a SafeArea. Reserve both its content height and the
    // persistent bottom inset so the panel body/FAB cannot be clipped on iOS.
    final bottomNavBarHeight = AppConstants.kAppBottomNavHeight +
        MediaQuery.viewPaddingOf(context).bottom;

    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final mainState = ref.watch(mainScaffoldProvider);
    final panelController = ref.watch(panelControllerProvider);
    final hasPlaybackItems = ref.watch(
      playerControllerProvider.select(
        (state) => state.playbackQueue.isNotEmpty,
      ),
    );
    final isCurrentVideoView = ref.watch(
      playerControllerProvider.select((state) => state.isCurrentVideoView),
    );
    if (isCurrentVideoView != _lastIsVideo) {
      _lastIsVideo = isCurrentVideoView;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _videoPresentationController.reset(expanded: false);
      });
    }

    Widget bodyContent;
    if (isMobile) {
      bodyContent = RepaintBoundary(child: widget.navigationShell);
    } else {
      bodyContent = Row(
        children: [
          AdaptiveNavigationRail(
            selectedIndex: selectedIndex,
            destinations: destinations,
            onDestinationSelected: (index) =>
                _navigateTo(destinations[index].branchIndex),
          ),
          Expanded(
            child: Column(
              children: [
                AdaptiveAppBar(
                  title: Text(title),
                  automaticallyImplyLeading: false,
                  height: kToolbarHeight,
                ),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      );
    }

    // 2. 缁熶竴浣跨敤 SlidingUpPanel 鍖呰
    return Scaffold(
      body: BackButtonPriorityWrapper(
        zIndex: 10,
        name: 'MainSlidingPlayer',
        onBack: () {
          if (isCurrentVideoView &&
              _videoPresentationController.progress > 0.02) {
            _videoPresentationController.collapse();
            return true;
          }
          if (mainState.isPlayerExpanded) {
            panelController.close();
            return true;
          }
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlayerSheetPanel(
              controller: panelController,
              minHeight: AppConstants.kMiniPlayerHeight,
              maxHeight: MediaQuery.sizeOf(context).height,
              showPanel: hasPlaybackItems && !isCurrentVideoView,
              fadeCollapsed: false,
              panelBuilder:
                  (ScrollController sc, AnimationController controller) {
                return PlayerView(
                  dragProgressNotifier: controller,
                  minHeight: AppConstants.kMiniPlayerHeight,
                );
              },
              body: bodyContent,
              showBottomNavBar: isMobile ? showBottomNav : false,
              bottomNavBarHeight: bottomNavBarHeight,
              bottomNavBar: isMobile
                  ? RepaintBoundary(
                      child: NavigationBar(
                        height: AppConstants.kAppBottomNavHeight,
                        maintainBottomViewPadding: true,
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (index) =>
                            _navigateTo(destinations[index].branchIndex),
                        destinations: destinations
                            .map(
                              (item) => NavigationDestination(
                                icon: item.icon,
                                label: item.label,
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : null,
              onPanelOpened: () => mainController.handlePanelStateChange(true),
              onPanelClosed: () => mainController.handlePanelStateChange(false),
            ),
            if (isCurrentVideoView)
              VideoFloatingOverlay(controller: _videoPresentationController),
          ],
        ),
      ),
    );
  }
}
