import 'package:flutter/material.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:provider/provider.dart';
import 'package:name_app/core/widgets/adaptive_app_bar.dart';
import 'package:name_app/features/home/presentation/pages/home_page.dart';
import 'package:name_app/features/user/presentation/pages/user_page.dart';
import 'package:name_app/features/auth/presentation/pages/auth_page.dart';
import 'package:name_app/features/settings/presentation/pages/settings_overview_page.dart';
import 'package:name_app/features/settings/presentation/pages/settings_page.dart';

/// A reusable sidebar layout that shows a NavigationRail on the left
/// and renders the provided [child] on the right.
class SideShell extends StatefulWidget {
  const SideShell({super.key});

  @override
  State<SideShell> createState() => _SideShellState();
}

class _SideShellState extends State<SideShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.themeMode == ThemeMode.dark;

    final pages = <Widget>[
      HomePage(onNavigate: (i) => setState(() => _selectedIndex = i)),
      const UserPage(),
      const AuthPage(),
      // Settings overview: clicking items switches to theme page within shell
      SettingsOverviewPage(
          onOpenTheme: () => setState(() => _selectedIndex = 4)),
      const SettingsPage(),
    ];

    final titles = <String>['首页', '用户', '认证', '设置', '主题'];
    final viewportHeight = MediaQuery.of(context).size.height;
    final headerHeight = viewportHeight * 0.08; // 10% of viewport

    return Scaffold(
      body: Row(
        children: [
          // Sidebar stays full-height; header will not sit above it
          NavigationRail(
            selectedIndex: _selectedIndex == 4
                ? 3
                : _selectedIndex, // pin rail to Settings when on Theme
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(padding: EdgeInsets.only(top: 30.0)),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('用户'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.lock_outline),
                selectedIcon: Icon(Icons.lock),
                label: Text('认证'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('设置'),
              ),
            ],
            trailing: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  IconButton(
                    tooltip: isDark ? '切换为浅色' : '切换为深色',
                    icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    onPressed: () => themeVM.toggleLightDark(),
                  ),
                ],
              ),
            ),
          ),
          // Content area with its own header (10% of viewport height)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: AdaptiveAppBar(
                    title: Text(titles[_selectedIndex]),
                    automaticallyImplyLeading: false,
                    height: headerHeight,
                  ),
                ),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
