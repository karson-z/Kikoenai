import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/core/widgets/layout/provider/main_scaffold_provider.dart'
    show mainScaffoldProvider;
import 'package:name_app/core/widgets/player/player_view.dart';
import 'package:name_app/core/widgets/player/test.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:name_app/config/navigation_item.dart';
import 'package:name_app/core/widgets/layout/navigation_rail.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar.dart';
final panelController = Provider((ref) => PanelController());

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {


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
    final scaffoldNotifier = ref.read(mainScaffoldProvider.notifier);
    final playController = ref.watch(panelController);
    debugPrint("rebuild");
    final int selectedIndex = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).uri.path;
    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool showBottomNav = scaffoldState.showBottomNav && !_isFullScreenPage(location);
    const double minHeight = 80;
    const double bottomNavHeight = 60;
    final double outerMaxHeight = MediaQuery.of(context).size.height;
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
        body: SlidingUpPanel(
          controller: playController,
          minHeight: minHeight,
          maxHeight: outerMaxHeight,
          isDraggable: scaffoldState.playerDraggable, // 内层打开外层阻止拖动手势
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          panel: Stack(
            children: [
              //  外层播放面板
              MusicPlayerView(
                onQueuePressed: () {
                  PlayerPlaylistSheet.show(context);
                },
              ),
            ],
          ),
          collapsed: GestureDetector(
            onTap: () {
              if (playController.isAttached) {
                 playController.open();
              }
            },
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Center(child: Text("Mini Player")),
            ),
          ),
          onPanelOpened: () {
            scaffoldNotifier.expandPlayer();
            scaffoldNotifier.setBottomNav(false);
          },
          onPanelClosed: () {
            scaffoldNotifier.collapsePlayer();
            scaffoldNotifier.setBottomNav(true);
          },
          body: Padding(
            padding: EdgeInsets.only(bottom: minHeight + (showBottomNav ? bottomNavHeight : 0)),
            child: widget.child ?? const SizedBox.shrink(),
          ),
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
        body: SlidingUpPanel(
          controller: playController,
          minHeight: minHeight,
          maxHeight: MediaQuery.of(context).size.height,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          panel: Stack(
            children: [
              //  外层播放面板
              MusicPlayerView(
                onQueuePressed: () {
                  PlayerPlaylistSheet.show(context);
                },
              ),
            ],
          ),
          collapsed: GestureDetector(
            onTap: () {
              if(!playController.isAttached){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("播放器未初始化，请刷新页面"),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              playController.open();
            },
            child: Container(
              height: minHeight,
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
              child: const Center(child: Text("Mini Player (Desktop) 全屏可见")),
            ),
          ),
          body: desktopLayoutRow,
        ),
      );
    }
  }
}
