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

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    debugPrint("init");
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
    final NavigationItem? selectedItem =
        selectedBranchIndex >= 0 &&
            selectedBranchIndex < appNavigationItems.length
        ? appNavigationItems[selectedBranchIndex]
        : null;
    final String title = selectedItem?.label ?? '';
    final bool isMobile = context.isMobile;
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool showBottomNav = AppRoutes.mainPages.contains(currentPath);

    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final mainState = ref.watch(mainScaffoldProvider);
    final panelController = ref.watch(panelControllerProvider);

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
          if (mainState.isPlayerExpanded) {
            panelController.close();
            return true;
          }
          return false;
        },
        child: PlayerSheetPanel(
          controller: panelController,
          minHeight: AppConstants.kMiniPlayerHeight,
          maxHeight: MediaQuery.sizeOf(context).height,
          fadeCollapsed: false,
          panelBuilder: (ScrollController sc, AnimationController controller) {
            return PlayerView(
              dragProgressNotifier: controller,
              minHeight: AppConstants.kMiniPlayerHeight,
            );
          },
          body: bodyContent,
          showBottomNavBar: isMobile ? showBottomNav : false,
          bottomNavBarHeight: AppConstants.kAppBottomNavHeight,
          bottomNavBar: isMobile
              ? RepaintBoundary(
                  child: NavigationBar(
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
      ),
    );
  }
}
