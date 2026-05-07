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
import '../../../features/player/presentation/page/player_view.dart';
import '../../utils/window/display_util.dart';
import '../common/back_button_interceptor.dart';
import '../slider/PlayerSheetPanel.dart';
// import 'app_player_slider.dart'; // 之前桌面端专用的组件可以安全移除了

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
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool showBottomNav = AppRoutes.mainPages.contains(currentPath);

    final mainController = ref.watch(mainScaffoldProvider.notifier);
    final mainState = ref.watch(mainScaffoldProvider);
    final panelController = ref.watch(panelControllerProvider);

    Widget bodyContent;
    if (isMobile) {
      bodyContent = widget.navigationShell;
    } else {
      bodyContent = Row(
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
                  child: widget.navigationShell,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 2. 统一使用 SlidingUpPanel 包装
    return Scaffold(
      body: BackButtonPriorityWrapper(
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
              ? NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _navigateTo(index),
            destinations: appNavigationItems
                .map((item) => NavigationDestination(
                icon: item.icon, label: item.label))
                .toList(),
          )
              : null, // 桌面端不渲染底部导航栏
          onPanelOpened: () => mainController.handlePanelStateChange(true),
          onPanelClosed: () => mainController.handlePanelStateChange(false),
        ),
      ),
    );
  }
}