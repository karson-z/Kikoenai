import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class WindowControlButtons extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const WindowControlButtons({
    super.key,
    this.iconSize = 16,
    this.iconColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        IconButton(
          tooltip: '最小化',
          icon: Icon(Icons.remove, size: iconSize, color: color),
          padding: padding,
          onPressed: () => appWindow.minimize(),
        ),
        IconButton(
          tooltip: appWindow.isMaximized ? '还原' : '最大化',
          icon: Icon(
            appWindow.isMaximized ? Icons.filter_none : Icons.crop_square,
            size: iconSize,
            color: color,
          ),
          padding: padding,
          onPressed: () => appWindow.maximizeOrRestore(),
        ),
        IconButton(
          tooltip: '关闭',
          icon: Icon(Icons.close, size: iconSize, color: color),
          padding: padding,
          onPressed: () => appWindow.close(),
        ),
      ],
    );
  }
}
