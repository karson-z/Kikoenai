import 'dart:math';

import 'package:flutter/material.dart';

class MorphingAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  MorphingAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

class MorphingCapsuleFab extends StatefulWidget {
  final List<MorphingAction> actions;
  final bool isExpanded;
  final ValueChanged<bool>? onChanged;
  final AxisDirection direction;
  final double fabSize;
  final IconData fabIcon;
  final double? expandedWidth;
  final double? expandedHeight;
  final double? collapsedRadius;
  final double? expandedRadius;

  const MorphingCapsuleFab({
    Key? key,
    required this.actions,
    this.isExpanded = false,
    this.onChanged,
    this.direction = AxisDirection.up,
    this.fabSize = 56.0,
    this.fabIcon = Icons.menu,
    this.expandedWidth,
    this.expandedHeight,
    this.collapsedRadius,
    this.expandedRadius,
  }) : super(key: key);

  @override
  State<MorphingCapsuleFab> createState() => _MorphingCapsuleFabState();
}
class _MorphingCapsuleFabState extends State<MorphingCapsuleFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curveAnimation;

  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _menuOpacityAnimation;

  late bool _internalIsExpanded;

  bool get _isHorizontal =>
      widget.direction == AxisDirection.left || widget.direction == AxisDirection.right;

  double get _targetWidth => widget.expandedWidth ?? (_isHorizontal ? 160.0 : 68.0);
  double get _targetHeight => widget.expandedHeight ?? (_isHorizontal ? 68.0 : 160.0);

  double get _targetRadius => widget.expandedRadius ?? (_isHorizontal ? _targetHeight / 2 : _targetWidth / 2);
  double get _initRadius => widget.collapsedRadius ?? (widget.fabSize / 2);

  double get _minorAxis => _isHorizontal ? _targetHeight : _targetWidth;
  double get _scaleFactor => _minorAxis / 68.0;

  @override
  void initState() {
    super.initState();
    // 初始化时，以外部传入的 isExpanded 为准
    _internalIsExpanded = widget.isExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      // 初始动画状态取决于当前的展开状态
      value: _internalIsExpanded ? 1.0 : 0.0,
    );

    _curveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _iconOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _menuOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(MorphingCapsuleFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged != null && widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理主 FAB 按钮的点击事件
  void _handleMainToggle() {
    if (widget.onChanged != null) {
      // 受控模式：交给父组件处理
      widget.onChanged!(!widget.isExpanded);
    } else {
      // 非受控模式：内部自己管理状态并驱动动画
      setState(() {
        _internalIsExpanded = !_internalIsExpanded;
      });
      if (_internalIsExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  Widget _buildActionItem(MorphingAction action) {
    final double scale = _scaleFactor;
    return Expanded(
      child: InkWell(
        onTap: () {
          // 1. 先执行按钮本身的业务逻辑
          action.onTap();

          // 2. 判断是否需要收起
          // 如果传了 onChanged (说明父组件接管了)，则通知父组件收起
          // 如果没传 onChanged (说明完全组件自己玩)，按你的要求，点击功能按钮不收起
          if (widget.onChanged != null) {
            widget.onChanged!(false);
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                color: action.iconColor,
                size: 24.0 * scale,
              ),
              SizedBox(height: 4.0 * scale),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11.0 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionWidgets() {
    final List<Widget> widgets = [];
    final double scale = _scaleFactor;

    for (int i = 0; i < widget.actions.length; i++) {
      widgets.add(_buildActionItem(widget.actions[i]));

      if (i < widget.actions.length - 1) {
        widgets.add(
          Container(
            width: _isHorizontal ? 1.0 : 32.0 * scale,
            height: _isHorizontal ? 32.0 * scale : 1.0,
            color: Colors.grey[200],
          ),
        );
      }
    }
    return widgets;
  }

  Alignment _getAlignment() {
    switch (widget.direction) {
      case AxisDirection.up:
        return Alignment.bottomCenter;
      case AxisDirection.down:
        return Alignment.topCenter;
      case AxisDirection.left:
        return Alignment.centerRight;
      case AxisDirection.right:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        // 这里需要判断使用哪个状态来做插值判断（如果你有其他的插值需求）
        // 动画的值主要靠 _controller 驱动，所以这里不用强依赖 isExpanded 变量
        final double currentWidth = Tween<double>(begin: widget.fabSize, end: _targetWidth).evaluate(_curveAnimation);
        final double currentHeight = Tween<double>(begin: widget.fabSize, end: _targetHeight).evaluate(_curveAnimation);
        final double currentRadius = Tween<double>(begin: _initRadius, end: _targetRadius).evaluate(_curveAnimation);

        return Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(currentRadius),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: currentWidth,
            height: currentHeight,
            child: Stack(
              alignment: _getAlignment(),
              children: [
                if (_menuOpacityAnimation.value > 0)
                  OverflowBox(
                    minWidth: _targetWidth,
                    maxWidth: _targetWidth,
                    minHeight: _targetHeight,
                    maxHeight: _targetHeight,
                    child: Opacity(
                      opacity: _menuOpacityAnimation.value,
                      child: _isHorizontal
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildActionWidgets(),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildActionWidgets(),
                      ),
                    ),
                  ),

                if (_iconOpacityAnimation.value > 0)
                  Align(
                    alignment: _getAlignment(),
                    child: SizedBox(
                      width: widget.fabSize,
                      height: widget.fabSize,
                      child: InkWell(
                        // 【修改点】点击主 FAB 图标时调用混合控制方法
                        onTap: _handleMainToggle,
                        child: Center(
                          child: Opacity(
                            opacity: _iconOpacityAnimation.value,
                            child: Icon(widget.fabIcon, size: 26.0),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}