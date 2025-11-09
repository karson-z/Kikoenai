import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

PreferredSizeWidget buildAdaptiveAppBar(
  BuildContext context, {
  Widget? title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  double? height = kToolbarHeight,
}) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
    return AppBar(
      title: title,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: height,
    );
  }

  final theme = Theme.of(context);
  final bg = theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
  final fg = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

  return PreferredSize(
    preferredSize: Size.fromHeight(height ?? kToolbarHeight),
    child: Container(
      height: height ?? kToolbarHeight, // ✅ 显式指定可见高度
      decoration: BoxDecoration(
        color: bg,
      ),
      child: Row(
        children: [
          Expanded(
            // ✅ 用 MoveWindow 扩大可拖拽范围，而非限制在 WindowTitleBarBox 内
            child: MoveWindow(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (automaticallyImplyLeading) const BackButton(),
                    if (title != null)
                      DefaultTextStyle(
                        style: TextStyle(
                          color: fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title,
                      ),
                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
          ),
          // 窗口按钮区
          _windowButtons(),
        ],
      ),
    ),
  );
}

Widget _windowButtons() {
  return Row(
    children: [
      IconButton(
        tooltip: '最小化',
        icon: const Icon(Icons.remove, size: 16),
        onPressed: () => appWindow.minimize(),
      ),
      IconButton(
        tooltip: appWindow.isMaximized ? '还原' : '最大化',
        icon: Icon(
          appWindow.isMaximized ? Icons.filter_none : Icons.crop_square,
          size: 16,
        ),
        onPressed: () => appWindow.maximizeOrRestore(),
      ),
      IconButton(
        tooltip: '关闭',
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => appWindow.close(),
      ),
    ],
  );
}
