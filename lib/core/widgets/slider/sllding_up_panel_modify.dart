/*
Name: Akshath Jain
Date: 3/18/2019 - 4/2/2020
Purpose: Defines the sliding_up_panel widget
Copyright: © 2020, Akshath Jain. All rights reserved.
Licensing: More information can be found here: https://github.com/akshathjain/sliding_up_panel/blob/master/LICENSE
*/

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter/physics.dart';

enum SlideDirection {
  UP,
  DOWN,
}

enum PanelState { OPEN, CLOSED }

class SlidingUpPanel extends StatefulWidget {
  final Widget? panel;

  // 修改点：增加 AnimationController 参数
  final Widget Function(ScrollController sc, AnimationController controller)? panelBuilder;

  final Widget? collapsed;
  final Widget? body;
  final Widget? header;
  final Widget? footer;
  final double minHeight;
  final double maxHeight;
  final double? snapPoint;
  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool renderPanelSheet;
  final bool panelSnapping;
  final PanelController? controller;
  final bool backdropEnabled;
  final Color backdropColor;
  final double backdropOpacity;
  final bool backdropTapClosesPanel;
  final void Function(double position)? onPanelSlide;
  final VoidCallback? onPanelOpened;
  final VoidCallback? onPanelClosed;
  final bool parallaxEnabled;
  final double parallaxOffset;
  final bool isDraggable;
  final SlideDirection slideDirection;
  final PanelState defaultPanelState;

  // 修改点：fadeCollapsed 参数
  final bool fadeCollapsed;

  SlidingUpPanel(
      {Key? key,
        this.panel,
        this.panelBuilder,
        this.body,
        this.collapsed,
        this.minHeight = 100.0,
        this.maxHeight = 500.0,
        this.snapPoint,
        this.border,
        this.borderRadius,
        this.boxShadow = const <BoxShadow>[
          BoxShadow(
            blurRadius: 8.0,
            color: Color.fromRGBO(0, 0, 0, 0.25),
          )
        ],
        this.color = Colors.white,
        this.padding,
        this.margin,
        this.renderPanelSheet = true,
        this.panelSnapping = true,
        this.controller,
        this.backdropEnabled = false,
        this.backdropColor = Colors.black,
        this.backdropOpacity = 0.5,
        this.backdropTapClosesPanel = true,
        this.onPanelSlide,
        this.onPanelOpened,
        this.onPanelClosed,
        this.parallaxEnabled = false,
        this.parallaxOffset = 0.1,
        this.isDraggable = true,
        this.slideDirection = SlideDirection.UP,
        this.defaultPanelState = PanelState.CLOSED,
        this.header,
        this.footer,
        this.fadeCollapsed = true
      })
      : assert(panel != null || panelBuilder != null),
        assert(0 <= backdropOpacity && backdropOpacity <= 1.0),
        assert(snapPoint == null || 0 < snapPoint && snapPoint < 1.0),
        super(key: key);

  @override
  _SlidingUpPanelState createState() => _SlidingUpPanelState();
}

class _SlidingUpPanelState extends State<SlidingUpPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late ScrollController _sc;

  // 【修改】：移除手动滚动手势追踪逻辑，全权交给 GestureDetector 竞技场
  // bool _scrollingEnabled = false;
  // VelocityTracker _vt = new VelocityTracker.withKind(PointerDeviceKind.touch);

  bool _isPanelVisible = true;

  @override
  void initState() {
    super.initState();

    _ac = new AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: widget.defaultPanelState == PanelState.CLOSED
            ? 0.0
            : 1.0
    )
      ..addListener(() {
        if (widget.onPanelSlide != null) widget.onPanelSlide!(_ac.value);

        if (widget.onPanelOpened != null && _ac.value == 1.0)
          widget.onPanelOpened!();

        if (widget.onPanelClosed != null && _ac.value == 0.0)
          widget.onPanelClosed!();
      });

    // 【修改】：这是一个 Dummy Controller，只为了满足 builder 签名
    // 不再监听它的 offset，因为我们不依赖它来判断是否可以拖动
    _sc = new ScrollController();

    widget.controller?._addState(this);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: widget.slideDirection == SlideDirection.UP
          ? Alignment.bottomCenter
          : Alignment.topCenter,
      children: <Widget>[
        // Body 部分
        widget.body != null
            ? AnimatedBuilder(
          animation: _ac,
          builder: (context, child) {
            return Positioned(
              top: widget.parallaxEnabled ? _getParallax() : 0.0,
              child: child ?? SizedBox(),
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: widget.body,
          ),
        )
            : Container(),

        // Backdrop 部分
        !widget.backdropEnabled
            ? Container()
            : GestureDetector(
          onVerticalDragEnd: widget.backdropTapClosesPanel
              ? (DragEndDetails dets) {
            if ((widget.slideDirection == SlideDirection.UP
                ? 1
                : -1) *
                dets.velocity.pixelsPerSecond.dy >
                0) _close();
          }
              : null,
          onTap: widget.backdropTapClosesPanel ? () => _close() : null,
          child: AnimatedBuilder(
              animation: _ac,
              builder: (context, _) {
                return Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: _ac.value == 0.0
                      ? null
                      : widget.backdropColor.withOpacity(
                      widget.backdropOpacity * _ac.value),
                );
              }),
        ),

        // 面板部分 (Actual Sliding Part)
        !_isPanelVisible
            ? Container()
            : _gestureHandler( // 【修改】：使用新的手势处理器
          child: AnimatedBuilder(
            animation: _ac,
            builder: (context, child) {
              return Container(
                height:
                _ac.value * (widget.maxHeight - widget.minHeight) +
                    widget.minHeight,
                margin: widget.margin,
                padding: widget.padding,
                decoration: widget.renderPanelSheet
                    ? BoxDecoration(
                  border: widget.border,
                  borderRadius: widget.borderRadius,
                  boxShadow: widget.boxShadow,
                  color: widget.color,
                )
                    : null,
                child: child,
              );
            },
            child: Stack(
              children: <Widget>[
                // Open panel content
                Positioned(
                    top: widget.slideDirection == SlideDirection.UP
                        ? 0.0
                        : null,
                    bottom: widget.slideDirection == SlideDirection.DOWN
                        ? 0.0
                        : null,
                    width: MediaQuery.of(context).size.width -
                        (widget.margin != null
                            ? widget.margin!.horizontal
                            : 0) -
                        (widget.padding != null
                            ? widget.padding!.horizontal
                            : 0),
                    child: Container(
                      height: widget.maxHeight,
                      child: widget.panel != null
                          ? widget.panel
                          : widget.panelBuilder!(_sc, _ac), // 传入 _ac
                    )),

                // Header
                widget.header != null
                    ? Positioned(
                  top: widget.slideDirection == SlideDirection.UP
                      ? 0.0
                      : null,
                  bottom:
                  widget.slideDirection == SlideDirection.DOWN
                      ? 0.0
                      : null,
                  child: widget.header ?? SizedBox(),
                )
                    : Container(),

                // Footer
                widget.footer != null
                    ? Positioned(
                    top: widget.slideDirection == SlideDirection.UP
                        ? null
                        : 0.0,
                    bottom:
                    widget.slideDirection == SlideDirection.DOWN
                        ? null
                        : 0.0,
                    child: widget.footer ?? SizedBox())
                    : Container(),

                // Collapsed panel content
                Positioned(
                  top: widget.slideDirection == SlideDirection.UP
                      ? 0.0
                      : null,
                  bottom: widget.slideDirection == SlideDirection.DOWN
                      ? 0.0
                      : null,
                  width: MediaQuery.of(context).size.width -
                      (widget.margin != null
                          ? widget.margin!.horizontal
                          : 0) -
                      (widget.padding != null
                          ? widget.padding!.horizontal
                          : 0),
                  child: Container(
                    height: widget.minHeight,
                    child: widget.collapsed == null
                        ? Container()
                        : widget.fadeCollapsed
                        ? FadeTransition(
                      opacity: Tween(begin: 1.0, end: 0.0)
                          .animate(_ac),
                      child: IgnorePointer(
                          ignoring: _isPanelOpen,
                          child: widget.collapsed),
                    )
                        : IgnorePointer(
                        ignoring: _isPanelOpen,
                        child: widget.collapsed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  double _getParallax() {
    if (widget.slideDirection == SlideDirection.UP)
      return -_ac.value *
          (widget.maxHeight - widget.minHeight) *
          widget.parallaxOffset;
    else
      return _ac.value *
          (widget.maxHeight - widget.minHeight) *
          widget.parallaxOffset;
  }

  // 【核心修改】：统一手势处理逻辑
  // 移除 Listener，使用 GestureDetector。
  // 这样 SlidingUpPanel 的手势和子组件的手势会进入"竞技场"竞争。
  // 如果子组件(歌词列表)处理了滑动，GestureDetector 就不会触发，面板不动。
  // 如果子组件没处理(比如到了边缘回弹，或者点击了header)，GestureDetector 触发，面板移动。
  Widget _gestureHandler({required Widget child}) {
    if (!widget.isDraggable) return child;

    return GestureDetector(
      // 允许点击事件穿透，但拖拽事件参与竞争
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (DragUpdateDetails dets) =>
          _onGestureSlide(dets.delta.dy),
      onVerticalDragEnd: (DragEndDetails dets) =>
          _onGestureEnd(dets.velocity),
      child: child,
    );
  }

  // 【修改】：简化的滑动逻辑
  // 不再判断 _scrollingEnabled，只要手势被 GestureDetector 捕获，就无条件移动面板
  void _onGestureSlide(double dy) {
    if (widget.slideDirection == SlideDirection.UP)
      _ac.value -= dy / (widget.maxHeight - widget.minHeight);
    else
      _ac.value += dy / (widget.maxHeight - widget.minHeight);
  }

  // 【修改】：简化的结束逻辑
  void _onGestureEnd(Velocity v) {
    double minFlingVelocity = 365.0;
    double kSnap = 8;

    if (_ac.isAnimating) return;

    double visualVelocity =
        -v.pixelsPerSecond.dy / (widget.maxHeight - widget.minHeight);

    if (widget.slideDirection == SlideDirection.DOWN)
      visualVelocity = -visualVelocity;

    double d2Close = _ac.value;
    double d2Open = 1 - _ac.value;
    double d2Snap = ((widget.snapPoint ?? 3) - _ac.value)
        .abs();
    double minDistance = min(d2Close, min(d2Snap, d2Open));

    if (v.pixelsPerSecond.dy.abs() >= minFlingVelocity) {
      if (widget.panelSnapping && widget.snapPoint != null) {
        if (v.pixelsPerSecond.dy.abs() >= kSnap * minFlingVelocity ||
            minDistance == d2Snap)
          _ac.fling(velocity: visualVelocity);
        else
          _flingPanelToPosition(widget.snapPoint!, visualVelocity);
      } else if (widget.panelSnapping) {
        _ac.fling(velocity: visualVelocity);
      } else {
        _ac.animateTo(
          _ac.value + visualVelocity * 0.16,
          duration: Duration(milliseconds: 410),
          curve: Curves.decelerate,
        );
      }

      return;
    }

    if (widget.panelSnapping) {
      if (minDistance == d2Close) {
        _close();
      } else if (minDistance == d2Snap) {
        _flingPanelToPosition(widget.snapPoint!, visualVelocity);
      } else {
        _open();
      }
    }
  }

  void _flingPanelToPosition(double targetPos, double velocity) {
    final Simulation simulation = SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1.0,
          stiffness: 500.0,
          ratio: 1.0,
        ),
        _ac.value,
        targetPos,
        velocity);

    _ac.animateWith(simulation);
  }

  //---------------------------------
  //PanelController related functions
  //---------------------------------
  // (后续代码保持不变，省略以节省空间，直接用你原文件的后续部分即可)

  Future<void> _close() {
    return _ac.fling(velocity: -1.0);
  }

  Future<void> _open() {
    return _ac.fling(velocity: 1.0);
  }

  Future<void> _hide() {
    return _ac.fling(velocity: -1.0).then((x) {
      setState(() {
        _isPanelVisible = false;
      });
    });
  }

  Future<void> _show() {
    return _ac.fling(velocity: -1.0).then((x) {
      setState(() {
        _isPanelVisible = true;
      });
    });
  }

  Future<void> _animatePanelToPosition(double value,
      {Duration? duration, Curve curve = Curves.linear}) {
    assert(0.0 <= value && value <= 1.0);
    return _ac.animateTo(value, duration: duration, curve: curve);
  }

  Future<void> _animatePanelToSnapPoint(
      {Duration? duration, Curve curve = Curves.linear}) {
    assert(widget.snapPoint != null);
    return _ac.animateTo(widget.snapPoint!, duration: duration, curve: curve);
  }

  set _panelPosition(double value) {
    assert(0.0 <= value && value <= 1.0);
    _ac.value = value;
  }

  double get _panelPosition => _ac.value;

  bool get _isPanelAnimating => _ac.isAnimating;

  bool get _isPanelOpen => _ac.value == 1.0;

  bool get _isPanelClosed => _ac.value == 0.0;

  bool get _isPanelShown => _isPanelVisible;
}

class PanelController {
  _SlidingUpPanelState? _panelState;

  void _addState(_SlidingUpPanelState panelState) {
    this._panelState = panelState;
  }

  bool get isAttached => _panelState != null;

  Future<void> close() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._close();
  }

  Future<void> open() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._open();
  }

  Future<void> hide() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._hide();
  }

  Future<void> show() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._show();
  }

  Future<void> animatePanelToPosition(double value,
      {Duration? duration, Curve curve = Curves.linear}) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(0.0 <= value && value <= 1.0);
    return _panelState!
        ._animatePanelToPosition(value, duration: duration, curve: curve);
  }

  Future<void> animatePanelToSnapPoint(
      {Duration? duration, Curve curve = Curves.linear}) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(_panelState!.widget.snapPoint != null,
    "SlidingUpPanel snapPoint property must not be null");
    return _panelState!
        ._animatePanelToSnapPoint(duration: duration, curve: curve);
  }

  set panelPosition(double value) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(0.0 <= value && value <= 1.0);
    _panelState!._panelPosition = value;
  }

  double get panelPosition {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._panelPosition;
  }

  bool get isPanelAnimating {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelAnimating;
  }

  bool get isPanelOpen {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelOpen;
  }

  bool get isPanelClosed {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelClosed;
  }

  bool get isPanelShown {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelShown;
  }
}