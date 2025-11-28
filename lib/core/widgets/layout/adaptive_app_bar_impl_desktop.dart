import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/core/widgets/common/global_search_input.dart';
import 'package:kikoenai/core/widgets/common/theme_toggle_button.dart';
import 'package:kikoenai/core/widgets/common/win_control_button.dart';

import '../../enums/device_type.dart';

PreferredSizeWidget buildAdaptiveAppBar(
  BuildContext context, {
  Widget? title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  double? height = kToolbarHeight,
}) {
  final theme = Theme.of(context);
  final deviceType = WorkListLayout(layoutType: WorkListLayoutType.card).getDeviceType(context);

  // ✅ Web 或非 Windows 平台
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height ?? kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: height,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 左侧可放 title 或其他控件
              if (deviceType == DeviceType.mobile) const ThemeToggleButton(),
              const Spacer(),
              // 右侧固定宽度搜索框
              SizedBox(
                width: 250,
                child: const GlobalSearchInput(
                  hintText: '搜索作品、作者或标签…',
                ),
              ),
              if (actions != null) ...actions,
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Windows 平台
  return PreferredSize(
    preferredSize: Size.fromHeight(height ?? kToolbarHeight),
    child: Container(
      height: height ?? kToolbarHeight,
      color: theme.appBarTheme.backgroundColor ?? Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (automaticallyImplyLeading) const BackButton(),
                    if (title != null)
                      DefaultTextStyle(
                        style: TextStyle(
                          color: theme.appBarTheme.foregroundColor ??
                              theme.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title,
                      ),
                    const Spacer(),
                    // 右侧固定宽度搜索框
                    SizedBox(
                      width: 250,
                      child: const GlobalSearchInput(
                        hintText: '搜索作品、作者或标签…',
                      ),
                    ),
                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
          ),
          const WindowControlButtons(),
        ],
      ),
    ),
  );
}
