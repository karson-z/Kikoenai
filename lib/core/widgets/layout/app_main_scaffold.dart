import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
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
    with TickerProviderStateMixin {
  late final VideoPresentationController _videoPresentationController;
  bool _lastIsVideo = false;

  @override
  void initState() {
    super.initState();
    _videoPresentationController = VideoPresentationController(
      vsync: this,
      beforeCollapse: () async {
        if (ref.read(mainScaffoldProvider).isFullScreen) {
          await ref
              .read(playerControllerProvider.notifier)
              .toggleVideoFullScreen();
        }
      },
    );
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
    const destinations = appNavigationItems;
    final int selectedBranchIndex = widget.navigationShell.currentIndex;
    final visibleSelectedIndex = destinations.indexWhere(
      (item) => item.branchIndex == selectedBranchIndex,
    );
    final selectedIndex = visibleSelectedIndex < 0 ? 0 : visibleSelectedIndex;
    final NavigationItem? selectedItem = appNavigationItems
        .where((item) => item.branchIndex == selectedBranchIndex)
        .firstOrNull;
    final String title = selectedItem?.label ?? '';
    final layout = context.layout;
    final useWideNavigation = layout.useWideNavigation;
    final railWidth = useWideNavigation
        ? AppLayoutTokens.navigationRailWidth
        : 0.0;
    final hasWindowControls =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool showBottomNav = AppRoutes.mainPages.contains(currentPath);
    // NavigationBar owns a SafeArea. Reserve both its content height and the
    // persistent bottom inset so the panel body/FAB cannot be clipped on iOS.
    final bottomNavBarHeight =
        layout.bottomNavigationHeight +
        MediaQuery.viewPaddingOf(context).bottom;

    final mainController = ref.read(mainScaffoldProvider.notifier);
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

    // Keep the navigation shell in the same slot while chrome changes around it.
    final bodyContent = SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: hasWindowControls ? 40 : 0,
            child: hasWindowControls
                ? const AdaptiveAppBar(title: Text('Kikoenai'), height: 40)
                : null,
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: railWidth),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: useWideNavigation
                            ? 64 + MediaQuery.paddingOf(context).top
                            : 0,
                        child: useWideNavigation
                            ? AdaptiveAppBar(
                                title: Text(title),
                                automaticallyImplyLeading: false,
                                height: 64,
                                includeWindowControls: false,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Builder(
                          // Read inside SafeArea so pages do not apply its
                          // horizontal insets a second time in landscape.
                          builder: (contentContext) => MediaQuery.removePadding(
                            context: contentContext,
                            removeTop: useWideNavigation || hasWindowControls,
                            child: RepaintBoundary(
                              child: widget.navigationShell,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final miniBottomPadding = useWideNavigation || !showBottomNav
        ? MediaQuery.viewPaddingOf(context).bottom
        : 0.0;
    final miniHeight = layout.miniPlayerHeight + miniBottomPadding;

    // 2. 缁熶竴浣跨敤 SlidingUpPanel 鍖呰
    return Scaffold(
      body: BackButtonPriorityWrapper(
        zIndex: 10,
        name: 'MainSlidingPlayer',
        onBack: () {
          if (isCurrentVideoView &&
              (mainState.isFullScreen ||
                  _videoPresentationController.progress > 0.02)) {
            _videoPresentationController.collapse();
            return true;
          }
          if (mainState.isPlayerExpanded) {
            panelController.close();
            return true;
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: hasWindowControls ? 40 : MediaQuery.paddingOf(context).top,
                bottom: 0,
                left: MediaQuery.paddingOf(context).left,
                width: railWidth,
                child: useWideNavigation
                    ? AdaptiveNavigationRail(
                        selectedIndex: selectedIndex,
                        destinations: destinations,
                        onDestinationSelected: (index) =>
                            _navigateTo(destinations[index].branchIndex),
                      )
                    : const SizedBox.shrink(),
              ),
              PlayerSheetPanel(
                controller: panelController,
                minHeight: miniHeight,
                maxHeight: constraints.maxHeight,
                collapsedInsets: EdgeInsets.only(
                  left: railWidth + MediaQuery.paddingOf(context).left,
                  right: MediaQuery.paddingOf(context).right,
                ),
                showPanel: hasPlaybackItems && !isCurrentVideoView,
                fadeCollapsed: false,
                panelBuilder:
                    (ScrollController sc, AnimationController controller) {
                      return PlayerView(
                        dragProgressNotifier: controller,
                        minHeight: miniHeight,
                        miniBottomPadding: miniBottomPadding,
                      );
                    },
                body: bodyContent,
                showBottomNavBar: !useWideNavigation && showBottomNav,
                bottomNavBarHeight: bottomNavBarHeight,
                bottomNavBar: !useWideNavigation
                    ? RepaintBoundary(
                        child: NavigationBar(
                          height: layout.bottomNavigationHeight,
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
                onPanelOpened: () =>
                    mainController.handlePanelStateChange(true),
                onPanelClosed: () =>
                    mainController.handlePanelStateChange(false),
              ),
              if (isCurrentVideoView)
                VideoFloatingOverlay(controller: _videoPresentationController),
            ],
          ),
        ),
      ),
    );
  }
}
