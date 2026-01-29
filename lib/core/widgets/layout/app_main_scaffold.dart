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

  // 使用 navigationShell.goBranch 进行切换
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

    //  直接从 shell 获取当前索引，不再需要根据 path 解析
    final int selectedIndex = widget.navigationShell.currentIndex;

    final String title = appNavigationItems.length > selectedIndex
        ? appNavigationItems[selectedIndex].label
        : '';

    final String location = GoRouterState.of(context).uri.path;

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool showBottomNav = scaffoldState.showBottomNav && !OtherUtil.isFullScreenPage(location);
    const double minHeight = 70;
    final double bottomNavHeight = AppConstants.kAppBottomNavHeight;

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
          minHeight: minHeight,
          maxHeight: MediaQuery.of(context).size.height,
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
                    padding: const EdgeInsets.only(bottom: minHeight),
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
          minHeight: minHeight,
          maxHeight: MediaQuery.of(context).size.height,
          body: desktopLayoutRow,
          controller: playController,
        ),
      );
    }
  }
}