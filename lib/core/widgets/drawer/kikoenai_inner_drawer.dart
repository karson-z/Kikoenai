import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class KikoenaiInnerDrawerHandle {
  double get progress;
  bool get isOpen;
  Future<void> open();
  Future<void> close();
}

class KikoenaiInnerDrawerController {
  KikoenaiInnerDrawerHandle? _handle;

  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  bool get isAttached => _handle != null;
  double get progress => progressNotifier.value;
  bool get isOpen => isOpenNotifier.value;

  void attach(KikoenaiInnerDrawerHandle handle) {
    _handle = handle;
    syncState(progress: handle.progress, isOpen: handle.isOpen);
  }

  void detach(KikoenaiInnerDrawerHandle handle) {
    if (_handle == handle) {
      _handle = null;
    }
  }

  void syncState({
    required double progress,
    required bool isOpen,
  }) {
    final nextProgress = progress.clamp(0.0, 1.0).toDouble();

    if (progressNotifier.value != nextProgress) {
      progressNotifier.value = nextProgress;
    }

    if (isOpenNotifier.value != isOpen) {
      isOpenNotifier.value = isOpen;
    }
  }

  Future<void> open() async {
    await _handle?.open();
  }

  Future<void> close() async {
    await _handle?.close();
  }

  Future<void> toggle() async {
    if (isOpen) {
      await close();
    } else {
      await open();
    }
  }

  void dispose() {
    progressNotifier.dispose();
    isOpenNotifier.dispose();
  }
}

class KikoenaiInnerDrawerScope extends InheritedWidget {
  const KikoenaiInnerDrawerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final KikoenaiInnerDrawerController controller;

  static KikoenaiInnerDrawerController of(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<KikoenaiInnerDrawerScope>();
    assert(scope != null, 'No KikoenaiInnerDrawerScope found in context');
    return scope!.controller;
  }

  static KikoenaiInnerDrawerController? maybeOf(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<KikoenaiInnerDrawerScope>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(covariant KikoenaiInnerDrawerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class KikoenaiInnerDrawer extends StatefulWidget {
  const KikoenaiInnerDrawer({
    super.key,
    required this.drawer,
    required this.child,
    required this.controller,
    this.drawerWidth = 300,
    this.maxSlideRatio = 0.82,
    this.borderRadius = 28,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
    this.enableDrag = true,
    this.edgeDragWidth = 24,
    this.scrimColor = Colors.black,
    this.scrimOpacity = 0.22,
    this.backgroundColor = const Color(0xFF111111),
    this.drawerParallax = 0.18,
    this.shadowBlur = 24,
    this.dragVelocityThreshold = 0.9,
    this.onProgressChanged,
    this.onOpened,
    this.onClosed,
  });

  /// 抽屉区域本身的内容。
  final Widget drawer;

  /// 主内容
  final Widget child;

  /// 抽屉控制器
  final KikoenaiInnerDrawerController controller;

  /// 抽屉的目标宽度
  final double drawerWidth;

  /// 抽屉最多可占屏幕宽度的比例
  final double maxSlideRatio;

  /// 前景主内容在抽屉展开时的最大圆角半径
  final double borderRadius;

  /// 抽屉自动开合动画的时长
  final Duration duration;

  /// 抽屉自动开合时使用的动画曲线
  final Curve curve;

  /// 是否允许手势拖拽
  final bool enableDrag;

  /// 从屏幕左侧边缘触发抽屉手势的有效宽度。
  ///
  /// 当抽屉关闭时，只有手指从左边这段区域开始拖动，
  /// 才会激活“打开抽屉”的拖拽逻辑。
  final double edgeDragWidth;

  /// 前景内容上的遮罩颜色
  ///
  /// 抽屉展开时，会在 [child] 上覆盖一层这个颜色的蒙层。
  final Color scrimColor;

  /// 前景内容遮罩的不透明度上限
  ///
  /// 实际绘制时会乘以抽屉展开进度：
  /// `实际透明度 = scrimOpacity * progress`
  final double scrimOpacity;

  /// 抽屉背后的背景色
  ///
  /// 通常用于填充左侧 drawer 区域之外的底色，
  /// 避免在动画过程中露出空白。
  final Color backgroundColor;

  /// 抽屉内容的视差强度。
  ///
  /// 值越大，抽屉在关闭到打开的过程中，
  /// 从左向右“跟随浮现”的感觉越明显，简单来说就是慢慢出现的感觉
  ///
  /// 为 0 时，drawer 不做额外视差位移。
  final double drawerParallax;

  /// 前景主内容阴影的模糊半径。
  ///
  /// 抽屉展开时，主内容卡片感会更强。
  /// 值越大，阴影越柔和、扩散越大。
  final double shadowBlur;

  /// 手势松开后，判定为“快速甩动”的速度阈值。
  ///
  /// 主要用于判断用户的意图是否想要真正打开，如果滑动的速度不够快有可能是用户误操作
  final double dragVelocityThreshold;

  /// 抽屉进度变化时的回调
  final ValueChanged<double>? onProgressChanged;

  /// 抽屉完全打开时触发的回调
  final VoidCallback? onOpened;

  /// 抽屉完全关闭时触发的回调
  final VoidCallback? onClosed;

  @override
  State<KikoenaiInnerDrawer> createState() => _KikoenaiInnerDrawerState();
}

class _KikoenaiInnerDrawerState extends State<KikoenaiInnerDrawer>
    with SingleTickerProviderStateMixin
    implements KikoenaiInnerDrawerHandle {
  late final AnimationController _ac;
  bool _dragEnabled = false;
  bool _lastOpenState = false;

  @override
  double get progress => _ac.value;

  @override
  bool get isOpen => _ac.value >= 0.999;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0.0,
    )..addListener(_handleAnimationTick);

    widget.controller.attach(this);
    _handleAnimationTick();
  }

  @override
  void didUpdateWidget(covariant KikoenaiInnerDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
      _handleAnimationTick();
    }

    if (oldWidget.duration != widget.duration) {
      _ac.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _ac
      ..removeListener(_handleAnimationTick)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    final nowOpen = isOpen;

    widget.controller.syncState(
      progress: _ac.value,
      isOpen: nowOpen,
    );

    widget.onProgressChanged?.call(_ac.value);

    if (nowOpen != _lastOpenState) {
      _lastOpenState = nowOpen;
      if (nowOpen) {
        widget.onOpened?.call();
      }
    }

    if (_ac.value <= 0.001 && _lastOpenState) {
      _lastOpenState = false;
      widget.onClosed?.call();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Future<void> open() {
    return _ac.animateTo(
      1.0,
      duration: widget.duration,
      curve: widget.curve,
    );
  }

  @override
  Future<void> close() {
    return _ac.animateTo(
      0.0,
      duration: widget.duration,
      curve: widget.curve,
    );
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enableDrag) return;

    final fromLeftEdge = details.localPosition.dx <= widget.edgeDragWidth;
    _dragEnabled = _ac.value > 0.0 || fromLeftEdge;

    if (_dragEnabled) {
      _ac.stop();
    }
  }

  void _onHorizontalDragUpdate(
      DragUpdateDetails details,
      double maxSlide,
      ) {
    if (!_dragEnabled) return;

    final delta = (details.primaryDelta ?? 0.0) / maxSlide;
    _ac.value = (_ac.value + delta).clamp(0.0, 1.0);
  }

  void _onHorizontalDragEnd(
      DragEndDetails details,
      double maxSlide,
      ) {
    if (!_dragEnabled) return;
    _dragEnabled = false;

    final velocity = details.velocity.pixelsPerSecond.dx / maxSlide;

    if (velocity.abs() >= widget.dragVelocityThreshold) {
      _ac.fling(velocity: velocity);
      return;
    }

    if (_ac.value >= 0.5) {
      open();
    } else {
      close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSlide = math.min(
          widget.drawerWidth,
          constraints.maxWidth * widget.maxSlideRatio,
        );

        final p = _ac.value;
        final drawerOffsetX = -maxSlide * widget.drawerParallax * (1 - p);
        final contentOffsetX = maxSlide * p;
        final radius = widget.borderRadius * p;
        final scrimOpacity = widget.scrimOpacity * p;
        final shadowOpacity = 0.18 * p;

        final foreground = Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (scrimOpacity > 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: close,
                  child: ColoredBox(
                    color: widget.scrimColor.withOpacity(scrimOpacity),
                  ),
                ),
              ),
          ],
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: widget.enableDrag
              ? _onHorizontalDragStart
              : null,
          onHorizontalDragUpdate: widget.enableDrag
              ? (details) => _onHorizontalDragUpdate(details, maxSlide)
              : null,
          onHorizontalDragEnd: widget.enableDrag
              ? (details) => _onHorizontalDragEnd(details, maxSlide)
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: widget.backgroundColor),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: maxSlide,
                child: Transform.translate(
                  offset: Offset(drawerOffsetX, 0),
                  child: RepaintBoundary(child: widget.drawer),
                ),
              ),
              Transform.translate(
                offset: Offset(contentOffsetX, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(shadowOpacity),
                          blurRadius: widget.shadowBlur,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: RepaintBoundary(child: foreground),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
