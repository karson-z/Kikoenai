import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart'
    show mainScaffoldProvider;
import 'package:kikoenai/core/widgets/player/player_view.dart';
import 'package:kikoenai/core/widgets/player/player_list_sheet.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/widgets/layout/navigation_rail.dart';
import 'package:kikoenai/core/widgets/layout/adaptive_app_bar.dart';

import '../player/player_mini_bar.dart';
import 'app_player_slider.dart';
final panelController = Provider((ref) => PanelController());

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  double slidePercent = 0.0; // 0 = 最小MiniPlayer, 1 = 展开

  @override
  void initState() {
    super.initState();
    debugPrint("init");
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final index = appNavigationItems.lastIndexWhere(
          (item) => location.startsWith(item.routePath),
    );
    return index == -1 ? 0 : index;
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == _calculateSelectedIndex(context)) return;
    context.go(appNavigationItems[index].routePath);
  }

  bool _isFullScreenPage(String location) {
    const fullScreenRoutes = [
      '/album/detail',
      '/settingsTheme',
    ];
    return fullScreenRoutes.contains(location);
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldState = ref.watch(mainScaffoldProvider);
    final playController = ref.watch(panelController);
    final int selectedIndex = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).uri.path;
    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool showBottomNav = scaffoldState.showBottomNav && !_isFullScreenPage(location);
    const double minHeight = 80;
    const double bottomNavHeight = 60;
    if (isMobile) {
      return Scaffold(
        bottomNavigationBar: showBottomNav
            ? NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _navigateTo(context, index),
          height: bottomNavHeight,
          destinations: appNavigationItems
              .map((item) => NavigationDestination(icon: item.icon, label: item.label))
              .toList(),
        )
            : null,
        body: SlidingPlayerPanel(
          minHeight: 80,
          maxHeight: MediaQuery.of(context).size.height,
          body: widget.child ?? const SizedBox.shrink(),
          collapsed: MiniPlayer(
            onTap: () {
              playController.open();
            },
          ),
          controller: playController,
        ),
      );
    } else {
      // 桌面端
      final desktopLayoutRow = Row(
        children: [
          AdaptiveNavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _navigateTo(context, index),
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
                    padding: EdgeInsets.only(bottom: minHeight),
                    child: widget.child ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      return Scaffold(
        body: SlidingPlayerPanel(
          minHeight: 80,
          maxHeight: MediaQuery.of(context).size.height,
          body: desktopLayoutRow,
          collapsed: MiniPlayer(
            onTap: () {
              playController.open();
            },
          ),
          controller: playController,
        ),
      );
    }
  }
}
