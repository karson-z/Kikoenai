import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 面板展开/收起的默认时长与曲线。
const Duration _kTopSheetDuration = Duration(milliseconds: 200);
const Curve _kTopSheetCurve = Curves.easeOutCubic;

/// 判定为「抛出」的最小竖向速度（逻辑像素/秒）。
const double _kMinFlingVelocity = 700.0;

/// 松手时低于该进度则收拢，高于则回弹展开。
const double _kCloseProgressThreshold = 0.5;

/// 从锚点向下延伸的模态面板。
///
/// 与 [showModalBottomSheet] 那种「贴在屏幕边缘的弹层」不同，它贴着调用方
/// [context] 所在控件（通常是筛选横条）向下展开，视觉上是横条自身「长出来」
/// 的一块内容，而不是从屏幕顶部盖下来。
///
/// * 面板顶边默认取 [context] 对应控件的全局顶边，也可用 [anchorTop] 显式指定；
/// * 遮罩只绘制在面板下方的区域（含底部导航栏），锚点以上保持原样不被压暗；
/// * [enableDrag] 开启时（默认），从面板的非滚动区域（摘要标题行、选项卡栏、
///   间距）上滑可收拢面板，上抛惯性关闭；面板内部的竖向滚动组件优先消费
///   滚动手势，与标准 [BottomSheet] 行为一致。
///
/// 路由挂在根 Navigator 上，因此：能盖住底部导航栏；返回键、点击遮罩
/// 都能关闭面板。
Future<T?> showTopSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? anchorTop,
  Color barrierColor = Colors.black26,
  bool barrierDismissible = true,
  String barrierLabel = '关闭',
  Duration transitionDuration = _kTopSheetDuration,
  bool enableDrag = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final double resolvedAnchorTop = anchorTop ?? topSheetAnchorTop(context);
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  return navigator.push<T>(
    ModalTopSheetRoute<T>(
      builder: builder,
      anchorTop: resolvedAnchorTop,
      barrierColor: barrierColor,
      isDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      sheetDuration: transitionDuration,
      enableDrag: enableDrag,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      settings: routeSettings,
    ),
  );
}

/// 量取 [context] 对应控件的全局顶边，作为面板的默认锚点。
///
/// 在弹面板之前、控件仍在树上时调用；取不到时退化为 0。
double topSheetAnchorTop(BuildContext context) {
  final RenderObject? renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero).dy;
  }
  return 0;
}

/// 从锚点向下延伸的模态弹层路由。
///
/// 路由负责遮罩、进出场动画与拖拽关闭。可见遮罩不是标准全屏 [ModalBarrier]：
/// 路由的 [barrierColor] 保持透明（仅用来吃掉点击），真正的压暗由页面内绘制，
/// 只覆盖 [anchorTop] 以下、面板之后的空间。
///
/// 拖拽通过直接改写路由动画控制器的值实现：上滑收拢、下滑展开，松手后按
/// [_kMinFlingVelocity]（抛出）与 [_kCloseProgressThreshold]（过半回弹）
/// 决定关闭或回弹，与 [BottomSheet] 的手势语义一致、方向相反。
class ModalTopSheetRoute<T> extends PopupRoute<T> {
  /// 创建一个向下延伸的顶部弹层路由。
  ModalTopSheetRoute({
    required this.builder,
    required this.anchorTop,
    this.capturedThemes,
    Color barrierColor = Colors.black26,
    this.isDismissible = true,
    this.barrierLabel = '关闭',
    this.sheetDuration = _kTopSheetDuration,
    this.enableDrag = true,
    super.settings,
  }) : dimColor = barrierColor,
       assert(anchorTop >= 0);

  /// 面板内容构建器。
  final WidgetBuilder builder;

  /// 面板顶边的全局 Y 坐标；面板从这里向下展开。
  final double anchorTop;

  /// 推入根 Navigator 时捕获的主题，保证弹层内外观一致。
  final CapturedThemes? capturedThemes;

  /// 面板下方可见遮罩的颜色。
  final Color dimColor;

  /// 是否允许点击遮罩关闭。
  final bool isDismissible;

  /// 是否允许上滑收拢/关闭面板。
  final bool enableDrag;

  /// 遮罩语义标签。
  @override
  final String barrierLabel;

  /// 进出场动画时长。
  final Duration sheetDuration;

  /// 路由的动画控制器，拖拽手势会直接改写它的值。
  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = super.createAnimationController();
    return _animationController!;
  }

  // 标准全屏遮罩保持透明：它只负责吃掉点击以便关闭，可见的压暗在页面内绘制。
  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Duration get transitionDuration => sheetDuration;

  @override
  Duration get reverseTransitionDuration => sheetDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    Widget content = _SheetPanel<T>(route: this, animation: animation);

    content = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: content,
    );

    return capturedThemes?.wrap(content) ?? content;
  }
}

/// 面板页本体：拖拽手势 + 揭示动画 + 分区遮罩。
class _SheetPanel<T> extends StatefulWidget {
  const _SheetPanel({required this.route, required this.animation});

  final ModalTopSheetRoute<T> route;

  /// 路由动画（控制器的原始驱动），拖拽期间直接映射它以保证跟手。
  final Animation<double> animation;

  @override
  State<_SheetPanel<T>> createState() => _SheetPanelState<T>();
}

class _SheetPanelState<T> extends State<_SheetPanel<T>> {
  final GlobalKey _panelKey = GlobalKey(debugLabel: 'TopSheet panel');

  /// 进出场用的缓动进度。
  late final CurvedAnimation _curvedSheetAnimation;

  /// 面板实际使用的进度；拖拽开始/结束时换绑父动画。
  late final ProxyAnimation _sheetAnimation;

  /// 松手后从精确进度续接用的曲线，再次换绑时释放上一个。
  CurvedAnimation? _handoffAnimation;

  @override
  void initState() {
    super.initState();
    _curvedSheetAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: _kTopSheetCurve,
    );
    _sheetAnimation = ProxyAnimation(_curvedSheetAnimation);
  }

  @override
  void didUpdateWidget(_SheetPanel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget.route == widget.route);
    assert(oldWidget.animation == widget.animation);
  }

  @override
  void dispose() {
    // 解除对路由动画的监听，避免泄漏。
    _sheetAnimation.parent = kAlwaysDismissedAnimation;
    _handoffAnimation?.dispose();
    _curvedSheetAnimation.dispose();
    super.dispose();
  }

  /// 面板内容的全高。面板始终按全高布局、只是被裁剪露出上半部分，
  /// 因此拖拽进度按全高换算即可与手指 1:1 对应。
  double get _panelHeight {
    final RenderBox renderBox =
        _panelKey.currentContext!.findRenderObject()! as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway =>
      widget.route._animationController!.status == AnimationStatus.reverse;

  void _handleDragStart(DragStartDetails details) {
    // 缓动曲线会让面板跟不上手指，拖拽期间改为直接映射路由动画原始值。
    _sheetAnimation.parent = widget.animation;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dismissUnderway) {
      return;
    }
    // 上滑（primaryDelta 为负）收拢面板、下滑展开。
    widget.route._animationController!.value +=
        details.primaryDelta! / _panelHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dismissUnderway) {
      return;
    }
    final AnimationController controller = widget.route._animationController!;
    final double currentProgress = controller.value;

    // 从松手的精确进度续接剩余过渡，避免视觉跳变。
    _rebindHandoff(currentProgress);

    var isClosing = false;
    if (details.velocity.pixelsPerSecond.dy < -_kMinFlingVelocity) {
      // 向上抛出：无论当前进度都收拢关闭。
      final double flingVelocity =
          details.velocity.pixelsPerSecond.dy / _panelHeight;
      if (controller.value > 0.0) {
        controller.fling(velocity: flingVelocity);
      }
      if (flingVelocity < 0.0) {
        isClosing = true;
      }
    } else if (controller.value < _kCloseProgressThreshold) {
      if (controller.value > 0.0) {
        controller.fling(velocity: -1.0);
      }
      isClosing = true;
    } else {
      controller.forward();
    }

    if (isClosing && widget.route.isCurrent) {
      Navigator.pop(context);
    }
  }

  void _rebindHandoff(double splitPoint) {
    _handoffAnimation?.dispose();
    _handoffAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Split(splitPoint, endCurve: _kTopSheetCurve),
    );
    _sheetAnimation.parent = _handoffAnimation;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (BuildContext context, Widget? child) {
        final double progress = _sheetAnimation.value.clamp(0.0, 1.0);
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double anchor = widget.route.anchorTop.clamp(
              0.0,
              constraints.maxHeight,
            );
            final double available = constraints.maxHeight - anchor;

            Widget panel = ConstrainedBox(
              constraints: BoxConstraints(maxHeight: available),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: progress,
                  // Align 给子节点的是松约束：宽度需显式撑满；高度保持全高
                  // 布局、仅被上方 ClipRect 裁剪，进度才能映射为露出的高度。
                  child: SizedBox(
                    key: _panelKey,
                    width: double.infinity,
                    child: Builder(builder: widget.route.builder),
                  ),
                ),
              ),
            );

            panel = widget.route.enableDrag
                ? _TopSheetGestureDetector(
                    onVerticalDragStart: _handleDragStart,
                    onVerticalDragUpdate: _handleDragUpdate,
                    onVerticalDragEnd: _handleDragEnd,
                    child: panel,
                  )
                // 吸收面板范围内的指针事件，避免点在内容间的空白缝隙时
                // 穿透到下方遮罩而误关面板。
                : Listener(behavior: HitTestBehavior.opaque, child: panel);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 锚点以上：不加遮罩，让工具栏/状态栏保持原样。
                SizedBox(height: anchor),
                panel,
                // 面板以下：压暗，覆盖页面内容与底部导航栏。
                Expanded(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: widget.route.dimColor.withValues(
                        alpha: widget.route.dimColor.a * progress,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 面板级的竖向拖拽识别器，语义同 [BottomSheet] 内部实现。
///
/// [RawGestureDetector.behavior] 设为 opaque，同时承担「面板区域吃掉点击」
/// 的职责（取代 [enableDrag] 关闭时的 [Listener]）。
class _TopSheetGestureDetector extends StatelessWidget {
  const _TopSheetGestureDetector({
    required this.child,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final Widget child;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (VerticalDragGestureRecognizer instance) {
                instance
                  ..onStart = onVerticalDragStart
                  ..onUpdate = onVerticalDragUpdate
                  ..onEnd = onVerticalDragEnd
                  // 需要更大的位移才认领手势，给面板内部滚动组件留出优先权。
                  ..onlyAcceptDragOnThreshold = true;
              },
            ),
      },
      child: child,
    );
  }
}
