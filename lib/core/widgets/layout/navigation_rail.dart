import 'package:flutter/material.dart';
import 'package:name_app/config/navigation_item.dart';
import 'package:name_app/core/widgets/common/theme_toggle_button.dart';

/// 自适应 NavigationRail 组件
class AdaptiveNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.selected,
      leading: const Padding(padding: EdgeInsets.only(top: 30.0)),
      destinations: appNavigationItems
          .map((item) => NavigationRailDestination(
                icon: item.icon,
                label: Text(item.label),
              ))
          .toList(),
      trailing:  Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Divider(),
          const ThemeToggleButton(),
        ],
      ),
    );
  }
}
