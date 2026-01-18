import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart'
    show mainScaffoldProvider;
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/widgets/layout/navigation_rail.dart';
import 'package:kikoenai/core/widgets/layout/adaptive_app_bar.dart';
import '../slider/sllding_up_panel_modify.dart';
import 'app_player_slider.dart';

final panelController = Provider((ref) => PanelController());

class MainScaffold extends ConsumerStatefulWidget {
  // 修改 1: 接收 StatefulNavigationShell 而不是 child
  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  // double slidePercent = 0.0; // 如果没用到可以移除

  @override
  void initState() {
    super.initState();
    debugPrint("init");
  }

  // 修改 2: 使用 navigationShell.goBranch 进行切换
  void _navigateTo(int index) {
    widget.navigationShell.goBranch(
      index,
      // 支持点击当前 Tab 回到顶部等初始状态（可选）
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldState = ref.watch(mainScaffoldProvider);
    final playController = ref.watch(panelController);

    // 修改 3: 直接从 shell 获取当前索引，不再需要根据 path 解析
    final int selectedIndex = widget.navigationShell.currentIndex;

    // 获取当前 Title (逻辑保持不变)
    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';

    // 获取当前路由路径用于全屏判断 (逻辑保持不变)
    // 注意: 使用 shell.shellRouteContext.routerState.uri.path 可能更准确，但原有方式也行
    final String location = GoRouterState.of(context).uri.path;

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool showBottomNav = scaffoldState.showBottomNav && !OtherUtil.isFullScreenPage(location);
    const double minHeight = 70;
    const double bottomNavHeight = AppConstants.kAppBarHeight;

    if (isMobile) {
      return Scaffold(
        bottomNavigationBar: showBottomNav
            ? NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _navigateTo(index),
          height: bottomNavHeight,
          destinations: appNavigationItems
              .map((item) => NavigationDestination(icon: item.icon, label: item.label))
              .toList(),
        )
            : null,
        body: SlidingPlayerPanel(
          minHeight: 80,
          maxHeight: MediaQuery.of(context).size.height,
          // 修改 4: body 传入 navigationShell，它就是那个 IndexedStack
          body: widget.navigationShell,
          controller: playController,
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
                    padding: EdgeInsets.only(bottom: minHeight),
                    // 修改 5: 传入 navigationShell
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
          minHeight: 80,
          maxHeight: MediaQuery.of(context).size.height,
          body: desktopLayoutRow,
          controller: playController,
        ),
      );
    }
  }
}