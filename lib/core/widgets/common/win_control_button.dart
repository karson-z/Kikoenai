import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControlButtons extends StatefulWidget {
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
  State<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends State<WindowControlButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  void _initWindowState() async {
    bool isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        IconButton(
          tooltip: '最小化',
          icon: Icon(Icons.remove, size: widget.iconSize, color: color),
          padding: widget.padding,
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          tooltip: _isMaximized ? '还原' : '最大化',
          icon: Icon(
            _isMaximized ? Icons.filter_none : Icons.crop_square,
            size: widget.iconSize,
            color: color,
          ),
          padding: widget.padding,
          onPressed: () async {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        IconButton(
          tooltip: '关闭',
          icon: Icon(Icons.close, size: widget.iconSize, color: color),
          padding: widget.padding,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}