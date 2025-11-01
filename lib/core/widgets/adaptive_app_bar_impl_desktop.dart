import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

PreferredSizeWidget buildAdaptiveAppBar(
  BuildContext context, {
  Widget? title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  double? height,
}) {
  // Only customize on Windows desktop; otherwise fallback to normal AppBar
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
    child: WindowTitleBarBox(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
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
                        child: Row(children: [title]),
                      ),
                    const Spacer(),
                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
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
        ),
      ),
    ),
  );
}
