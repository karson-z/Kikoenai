import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/core/utils/window/window_close_handler.dart';
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
  ConsumerState<WindowControlButtons> createState() =>
      _WindowControlButtonsState();
}

class _WindowControlButtonsState extends ConsumerState<WindowControlButtons>
    with WindowListener {
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
    final color =
        widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final isFullScreen = ref.watch(mainScaffoldProvider).isFullScreen;
    final canSearch = ref.watch(
      surfaceAvailableProvider(AppSurface.searchPage),
    );

    return Row(
      children: [
        if (canSearch) ...[
          IconButton(
            tooltip: '搜索',
            icon: Icon(
              Icons.search_rounded,
              size: widget.iconSize,
              color: color,
            ),
            padding: widget.padding,
            onPressed: () {
              context.push(AppRoutes.search);
            },
          ),
          const SizedBox(width: 8),
          const SizedBox(
            height: 20, // 限制垂直线的绝对高度
            child: VerticalDivider(
              width: 1, // 占用的水平空间
              thickness: 1, // 线的物理粗细
              color: Colors.grey, // 线的颜色，可替换为 Theme.of(context).dividerColor
            ),
          ),
          const SizedBox(width: 8),
        ],
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
          onPressed: () => WindowCloseHandler.handleClose(context),
        ),
      ],
    );
  }

  /// 系统级关闭（标题栏 X / Alt+F4）：因 setPreventClose(true) 触发，
  /// 走与关闭按钮相同的逻辑，保证已记住的选择 / 弹窗一致。
  @override
  void onWindowClose() {
    WindowCloseHandler.handleClose(context);
  }
}
