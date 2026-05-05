import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart'
    show mainScaffoldProvider;
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/widgets/layout/navigation_rail.dart';
import 'package:kikoenai/core/widgets/layout/adaptive_app_bar.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import '../slider/sllding_up_panel_modify.dart';
import 'app_player_slider.dart';

final panelControllerProvider = Provider((ref) => PanelController());

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

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
  void _navigateTo(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
  @override
  Widget build(BuildContext context) {
    final int selectedIndex = widget.navigationShell.currentIndex;
    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';
    final bool isMobile = context.isMobile;
    const double minHeight = 75;
    final double bottomNavHeight = AppConstants.kAppBottomNavHeight;
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool showBottomNav = AppRoutes.mainPages.contains(currentPath);
    if (isMobile) {
      return Scaffold(
        bottomNavigationBar: showBottomNav ? NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _navigateTo(index),
          height: bottomNavHeight,
          destinations: appNavigationItems
              .map((item) => NavigationDestination(icon: item.icon, label: item.label))
              .toList(),
        ) : null,
        body: SlidingPlayerPanel(
          minHeight: minHeight,
          maxHeight: MediaQuery.sizeOf(context).height,
          body: widget.navigationShell,
        ),
      );
    } else {
      // 桌面端
      final desktopLayoutRow = Row(
        children: [
          AdaptiveNavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _navigateTo(index),
          ),
          Expanded(
            child: Column(
              children: [
                AdaptiveAppBar(
                  title: Text(title),
                  automaticallyImplyLeading: false,
                  height: kToolbarHeight,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: minHeight),
                    child: widget.navigationShell,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      return Scaffold(
        body: SlidingPlayerPanel(
          minHeight: minHeight,
          maxHeight: MediaQuery.sizeOf(context).height,
          body: desktopLayoutRow,
        ),
      );
    }
  }
}
