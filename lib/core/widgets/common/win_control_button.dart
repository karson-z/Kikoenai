import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../layout/provider/main_scaffold_provider.dart';

class WindowControlButtons extends ConsumerStatefulWidget {
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const WindowControlButtons({
    super.key,
    this.iconSize = 18,
    this.iconColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  @override
  ConsumerState<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends ConsumerState<WindowControlButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  void _initWindowState() async {
    bool isMaximized = await windowManager.isMaximized();
    bool isFullScreen = await windowManager.isFullScreen();

    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
      ref.read(mainScaffoldProvider.notifier).setFullScreen(isFullScreen);
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
  void onWindowEnterFullScreen() {
    ref.read(mainScaffoldProvider.notifier).setFullScreen(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    ref.read(mainScaffoldProvider.notifier).setFullScreen(false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final isFullScreen = ref.watch(mainScaffoldProvider).isFullScreen;

    return Row(
      children: [
        IconButton(
          tooltip: isFullScreen ? '退出全屏' : '全屏',
          icon: Icon(
            isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            size: widget.iconSize,
            color: color,
          ),
          padding: widget.padding,
          onPressed: () {
            windowManager.setFullScreen(!isFullScreen);
          },
        ),
        const SizedBox(width: 8),
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