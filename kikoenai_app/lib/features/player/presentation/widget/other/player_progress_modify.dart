import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 进度条组件
/// 支持拖动时平滑放大，并自动保持垂直居中不影响外部布局
class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    required this.total,
    this.buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.height = 24.0, // 新增：组件的固定占位高度（防止动画挤压外部布局）
    this.barHeight = 5.0,
    this.draggingBarHeight = 8.0, // 新增：拖动时的高度
    this.baseBarColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.barCapShape = BarCapShape.round,
    this.thumbRadius = 6.0,
    this.draggingThumbRadius = 9.0, // 新增：拖动时的滑块半径
    this.thumbColor,
    this.thumbGlowColor,
    this.thumbGlowRadius = 16.0,
    this.thumbCanPaintOutsideBar = true,
    this.timeLabelLocation,
    this.timeLabelType,
    this.timeLabelTextStyle,
    this.timeLabelPadding = 0.0,
    this.isLoading = false,
  });

  final Duration progress;
  final Duration total;
  final Duration? buffered;
  final ValueChanged<Duration>? onSeek;
  final ThumbDragStartCallback? onDragStart;
  final ThumbDragUpdateCallback? onDragUpdate;
  final VoidCallback? onDragEnd;

  final double? height;
  final double barHeight;
  final double draggingBarHeight;

  final Color? baseBarColor;
  final Color? progressBarColor;
  final Color? bufferedBarColor;
  final BarCapShape barCapShape;

  final double thumbRadius;
  final double draggingThumbRadius;

  final Color? thumbColor;
  final Color? thumbGlowColor;
  final double thumbGlowRadius;
  final bool thumbCanPaintOutsideBar;
  final TimeLabelLocation? timeLabelLocation;
  final TimeLabelType? timeLabelType;
  final TextStyle? timeLabelTextStyle;
  final double timeLabelPadding;
  final bool isLoading;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDragging = false; // 在组件内部维护拖动状态

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 核心实现：包裹平滑过渡动画
    Widget content = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _isDragging ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        // 动态插值计算
        final currentBarHeight = widget.barHeight +
            ((widget.draggingBarHeight - widget.barHeight) * animValue);
        final currentThumbRadius = widget.thumbRadius +
            ((widget.draggingThumbRadius - widget.thumbRadius) * animValue);
        final currentGlowRadius = widget.thumbGlowRadius + (4.0 * animValue);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 使用 Center 保证高度变大时，是向上下均匀扩张的
            return Center(
              child: _ProgressBarRenderObjectWidget(
                progress: widget.progress,
                total: widget.total,
                buffered: widget.buffered,
                onSeek: widget.onSeek,
                // 拦截回调，更新内部动画状态，并将事件透传给外部
                onDragStart: (details) {
                  setState(() => _isDragging = true);
                  widget.onDragStart?.call(details);
                },
                onDragUpdate: widget.onDragUpdate,
                onDragEnd: () {
                  setState(() => _isDragging = false);
                  widget.onDragEnd?.call();
                },
                barHeight: currentBarHeight,
                baseBarColor: widget.baseBarColor,
                progressBarColor: widget.progressBarColor,
                bufferedBarColor: widget.bufferedBarColor,
                barCapShape: widget.barCapShape,
                thumbRadius: currentThumbRadius,
                thumbColor: widget.thumbColor,
                thumbGlowColor: widget.thumbGlowColor,
                thumbGlowRadius: currentGlowRadius,
                thumbCanPaintOutsideBar: widget.thumbCanPaintOutsideBar,
                timeLabelLocation: widget.timeLabelLocation,
                timeLabelType: widget.timeLabelType,
                timeLabelTextStyle: widget.timeLabelTextStyle,
                timeLabelPadding: widget.timeLabelPadding,
                isLoading: widget.isLoading,
                loadingAnimationValue: _controller.value,
              ),
            );
          },
        );
      },
    );

    // 用固定高度保护外部布局不被挤压
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: content);
    }
    return content;
  }
}

// --------------------------------------------------------------------------
// 下方的底层渲染代码几乎保持原样，只修复了手势取消的 Bug
// --------------------------------------------------------------------------

class _ProgressBarRenderObjectWidget extends LeafRenderObjectWidget {
  const _ProgressBarRenderObjectWidget({
    required this.progress,
    required this.total,
    this.buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    required this.barHeight,
    this.baseBarColor,
    this.progressBarColor,
    this.bufferedBarColor,
    required this.barCapShape,
    required this.thumbRadius,
    this.thumbColor,
    this.thumbGlowColor,
    required this.thumbGlowRadius,
    required this.thumbCanPaintOutsideBar,
    this.timeLabelLocation,
    this.timeLabelType,
    this.timeLabelTextStyle,
    required this.timeLabelPadding,
    required this.isLoading,
    required this.loadingAnimationValue,
  });

  final Duration progress;
  final Duration total;
  final Duration? buffered;
  final ValueChanged<Duration>? onSeek;
  final ThumbDragStartCallback? onDragStart;
  final ThumbDragUpdateCallback? onDragUpdate;
  final VoidCallback? onDragEnd;
  final double barHeight;
  final Color? baseBarColor;
  final Color? progressBarColor;
  final Color? bufferedBarColor;
  final BarCapShape barCapShape;
  final double thumbRadius;
  final Color? thumbColor;
  final Color? thumbGlowColor;
  final double thumbGlowRadius;
  final bool thumbCanPaintOutsideBar;
  final TimeLabelLocation? timeLabelLocation;
  final TimeLabelType? timeLabelType;
  final TextStyle? timeLabelTextStyle;
  final double timeLabelPadding;
  final bool isLoading;
  final double loadingAnimationValue;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyLarge;
    final textScaler = MediaQuery.textScalerOf(context);
    return _RenderProgressBar(
      progress: progress,
      total: total,
      buffered: buffered ?? Duration.zero,
      onSeek: onSeek,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      barHeight: barHeight,
      baseBarColor: baseBarColor ?? primaryColor.withOpacity(0.24),
      progressBarColor: progressBarColor ?? primaryColor,
      bufferedBarColor: bufferedBarColor ?? primaryColor.withOpacity(0.24),
      barCapShape: barCapShape,
      thumbRadius: thumbRadius,
      thumbColor: thumbColor ?? primaryColor,
      thumbGlowColor: thumbGlowColor ?? (thumbColor ?? primaryColor).withAlpha(80),
      thumbGlowRadius: thumbGlowRadius,
      thumbCanPaintOutsideBar: thumbCanPaintOutsideBar,
      timeLabelLocation: timeLabelLocation ?? TimeLabelLocation.below,
      timeLabelType: timeLabelType ?? TimeLabelType.totalTime,
      timeLabelTextStyle: textStyle,
      timeLabelPadding: timeLabelPadding,
      textScaler: textScaler,
      isLoading: isLoading,
      loadingAnimationValue: loadingAnimationValue,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyLarge;
    final textScaler = MediaQuery.textScalerOf(context);
    (renderObject as _RenderProgressBar)
      ..progress = progress
      ..total = total
      ..buffered = buffered ?? Duration.zero
      ..onSeek = onSeek
      ..onDragStart = onDragStart
      ..onDragUpdate = onDragUpdate
      ..onDragEnd = onDragEnd
      ..barHeight = barHeight
      ..baseBarColor = baseBarColor ?? primaryColor.withOpacity(0.24)
      ..progressBarColor = progressBarColor ?? primaryColor
      ..bufferedBarColor = bufferedBarColor ?? primaryColor.withOpacity(0.24)
      ..barCapShape = barCapShape
      ..thumbRadius = thumbRadius
      ..thumbColor = thumbColor ?? primaryColor
      ..thumbGlowColor = thumbGlowColor ?? (thumbColor ?? primaryColor).withAlpha(80)
      ..thumbGlowRadius = thumbGlowRadius
      ..thumbCanPaintOutsideBar = thumbCanPaintOutsideBar
      ..timeLabelLocation = timeLabelLocation ?? TimeLabelLocation.below
      ..timeLabelType = timeLabelType ?? TimeLabelType.totalTime
      ..timeLabelTextStyle = textStyle
      ..timeLabelPadding = timeLabelPadding
      ..textScaler = textScaler
      ..isLoading = isLoading
      ..loadingAnimationValue = loadingAnimationValue;
  }
}

enum TimeLabelLocation { above, below, sides, none }
enum TimeLabelType { totalTime, remainingTime }
enum BarCapShape { round, square }

typedef ThumbDragStartCallback = void Function(ThumbDragDetails details);
typedef ThumbDragUpdateCallback = void Function(ThumbDragDetails details);

class ThumbDragDetails {
  const ThumbDragDetails({
    this.timeStamp = Duration.zero,
    this.globalPosition = Offset.zero,
    this.localPosition = Offset.zero,
  });
  final Duration timeStamp;
  final Offset globalPosition;
  final Offset localPosition;
}

class _EagerHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
  @override
  String get debugDescription => '_EagerHorizontalDragGestureRecognizer';
}

class _RenderProgressBar extends RenderBox {
  _RenderProgressBar({
    required Duration progress,
    required Duration total,
    required Duration buffered,
    ValueChanged<Duration>? onSeek,
    ThumbDragStartCallback? onDragStart,
    ThumbDragUpdateCallback? onDragUpdate,
    VoidCallback? onDragEnd,
    required double barHeight,
    required Color baseBarColor,
    required Color progressBarColor,
    required Color bufferedBarColor,
    required BarCapShape barCapShape,
    required double thumbRadius,
    required Color thumbColor,
    required Color thumbGlowColor,
    required double thumbGlowRadius,
    required bool thumbCanPaintOutsideBar,
    required TimeLabelLocation timeLabelLocation,
    required TimeLabelType timeLabelType,
    TextStyle? timeLabelTextStyle,
    required double timeLabelPadding,
    required TextScaler textScaler,
    required bool isLoading,
    required double loadingAnimationValue,
  })  : _total = total,
        _buffered = buffered,
        _onSeek = onSeek,
        _onDragStartUserCallback = onDragStart,
        _onDragUpdateUserCallback = onDragUpdate,
        _onDragEndUserCallback = onDragEnd,
        _barHeight = barHeight,
        _baseBarColor = baseBarColor,
        _progressBarColor = progressBarColor,
        _bufferedBarColor = bufferedBarColor,
        _barCapShape = barCapShape,
        _thumbRadius = thumbRadius,
        _thumbColor = thumbColor,
        _thumbGlowColor = thumbGlowColor,
        _thumbGlowRadius = thumbGlowRadius,
        _thumbCanPaintOutsideBar = thumbCanPaintOutsideBar,
        _timeLabelLocation = timeLabelLocation,
        _timeLabelType = timeLabelType,
        _timeLabelTextStyle = timeLabelTextStyle,
        _timeLabelPadding = timeLabelPadding,
        _textScaler = textScaler,
        _isLoading = isLoading,
        _loadingAnimationValue = loadingAnimationValue {
    _drag = _EagerHorizontalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd
      ..onCancel = _onDragCancel; // 修复：绑定取消事件
    if (!_userIsDraggingThumb) {
      _progress = progress;
      _thumbValue = _proportionOfTotal(_progress);
    }
  }

  _EagerHorizontalDragGestureRecognizer? _drag;
  late double _thumbValue;
  bool _userIsDraggingThumb = false;

  bool get isLoading => _isLoading;
  bool _isLoading;
  set isLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    markNeedsPaint();
  }

  double get loadingAnimationValue => _loadingAnimationValue;
  double _loadingAnimationValue;
  set loadingAnimationValue(double value) {
    if (_loadingAnimationValue == value) return;
    _loadingAnimationValue = value;
    markNeedsPaint();
  }

  double get _defaultSidePadding {
    const minPadding = 5.0;
    return (_thumbCanPaintOutsideBar) ? thumbRadius + minPadding : minPadding;
  }

  void _onDragStart(DragStartDetails details) {
    _userIsDraggingThumb = true;
    _updateThumbPosition(details.localPosition);
    onDragStart?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    ));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateThumbPosition(details.localPosition);
    onDragUpdate?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    ));
  }

  void _onDragEnd(DragEndDetails details) {
    onDragEnd?.call();
    onSeek?.call(_currentThumbDuration());
    _finishDrag();
  }

  // 修复：手势被外部打断时（如列表滚动），必须回调通知 State 恢复 UI 状态
  void _onDragCancel() {
    onDragEnd?.call();
    _finishDrag();
  }

  void _finishDrag() {
    _userIsDraggingThumb = false;
    markNeedsPaint();
  }

  Duration _currentThumbDuration() {
    final thumbMilliseconds = _thumbValue * total.inMilliseconds;
    return Duration(milliseconds: thumbMilliseconds.round());
  }

  void _updateThumbPosition(Offset localPosition) {
    final dx = localPosition.dx;
    double lengthBefore = 0.0;
    double lengthAfter = 0.0;
    if (_timeLabelLocation == TimeLabelLocation.sides) {
      lengthBefore = _leftLabelSize.width + _defaultSidePadding + _timeLabelPadding;
      lengthAfter = _rightLabelSize.width + _defaultSidePadding + _timeLabelPadding;
    }
    final barCapRadius = _barHeight / 2;
    double barStart = lengthBefore + barCapRadius;
    double barEnd = size.width - lengthAfter - barCapRadius;
    final barWidth = barEnd - barStart;
    final position = (dx - barStart).clamp(0.0, barWidth);
    _thumbValue = (position / barWidth);
    _progress = _currentThumbDuration();
    markNeedsPaint();
  }

  Duration get progress => _progress;
  Duration _progress = Duration.zero;
  set progress(Duration value) {
    final clamp = _clampDuration(value);
    if (_progress == clamp) return;
    if (_labelLengthDifferent(_progress, clamp)) _clearLabelCache();
    if (!_userIsDraggingThumb) {
      _progress = clamp;
      _thumbValue = _proportionOfTotal(clamp);
    }
    markNeedsPaint();
  }

  Duration get total => _total;
  Duration _total;
  set total(Duration value) {
    final clamp = (value.isNegative) ? Duration.zero : value;
    if (_total == clamp) return;
    if (_labelLengthDifferent(_total, clamp)) _clearLabelCache();
    _total = clamp;
    if (!_userIsDraggingThumb) _thumbValue = _proportionOfTotal(progress);
    markNeedsPaint();
  }

  Duration get buffered => _buffered;
  Duration _buffered;
  set buffered(Duration value) {
    final clamp = _clampDuration(value);
    if (_buffered == clamp) return;
    _buffered = clamp;
    markNeedsPaint();
  }

  ValueChanged<Duration>? get onSeek => _onSeek;
  ValueChanged<Duration>? _onSeek;
  set onSeek(ValueChanged<Duration>? value) { if (value == _onSeek) return; _onSeek = value; }

  ThumbDragStartCallback? get onDragStart => _onDragStartUserCallback;
  ThumbDragStartCallback? _onDragStartUserCallback;
  set onDragStart(ThumbDragStartCallback? value) { if (value == _onDragStartUserCallback) return; _onDragStartUserCallback = value; }

  ThumbDragUpdateCallback? get onDragUpdate => _onDragUpdateUserCallback;
  ThumbDragUpdateCallback? _onDragUpdateUserCallback;
  set onDragUpdate(ThumbDragUpdateCallback? value) { if (value == _onDragUpdateUserCallback) return; _onDragUpdateUserCallback = value; }

  VoidCallback? get onDragEnd => _onDragEndUserCallback;
  VoidCallback? _onDragEndUserCallback;
  set onDragEnd(VoidCallback? value) { if (value == _onDragEndUserCallback) return; _onDragEndUserCallback = value; }

  double get barHeight => _barHeight;
  double _barHeight;
  set barHeight(double value) { if (_barHeight == value) return; _barHeight = value; markNeedsPaint(); }

  Color get baseBarColor => _baseBarColor;
  Color _baseBarColor;
  set baseBarColor(Color value) { if (_baseBarColor == value) return; _baseBarColor = value; markNeedsPaint(); }

  Color get progressBarColor => _progressBarColor;
  Color _progressBarColor;
  set progressBarColor(Color value) { if (_progressBarColor == value) return; _progressBarColor = value; markNeedsPaint(); }

  Color get bufferedBarColor => _bufferedBarColor;
  Color _bufferedBarColor;
  set bufferedBarColor(Color value) { if (_bufferedBarColor == value) return; _bufferedBarColor = value; markNeedsPaint(); }

  BarCapShape get barCapShape => _barCapShape;
  BarCapShape _barCapShape;
  set barCapShape(BarCapShape value) { if (_barCapShape == value) return; _barCapShape = value; markNeedsPaint(); }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;
  set thumbColor(Color value) { if (_thumbColor == value) return; _thumbColor = value; markNeedsPaint(); }

  double get thumbRadius => _thumbRadius;
  double _thumbRadius;
  set thumbRadius(double value) { if (_thumbRadius == value) return; _thumbRadius = value; markNeedsLayout(); }

  Color get thumbGlowColor => _thumbGlowColor;
  Color _thumbGlowColor;
  set thumbGlowColor(Color value) { if (_thumbGlowColor == value) return; _thumbGlowColor = value; if (_userIsDraggingThumb) markNeedsPaint(); }

  double get thumbGlowRadius => _thumbGlowRadius;
  double _thumbGlowRadius;
  set thumbGlowRadius(double value) { if (_thumbGlowRadius == value) return; _thumbGlowRadius = value; markNeedsLayout(); }

  bool get thumbCanPaintOutsideBar => _thumbCanPaintOutsideBar;
  bool _thumbCanPaintOutsideBar;
  set thumbCanPaintOutsideBar(bool value) { if (_thumbCanPaintOutsideBar == value) return; _thumbCanPaintOutsideBar = value; markNeedsPaint(); }

  TimeLabelLocation get timeLabelLocation => _timeLabelLocation;
  TimeLabelLocation _timeLabelLocation;
  set timeLabelLocation(TimeLabelLocation value) { if (_timeLabelLocation == value) return; _timeLabelLocation = value; markNeedsLayout(); }

  TimeLabelType get timeLabelType => _timeLabelType;
  TimeLabelType _timeLabelType;
  set timeLabelType(TimeLabelType value) { if (_timeLabelType == value) return; _timeLabelType = value; _clearLabelCache(); markNeedsLayout(); }

  TextStyle? get timeLabelTextStyle => _timeLabelTextStyle;
  TextStyle? _timeLabelTextStyle;
  set timeLabelTextStyle(TextStyle? value) { if (_timeLabelTextStyle == value) return; _timeLabelTextStyle = value; _clearLabelCache(); markNeedsLayout(); }

  double get timeLabelPadding => _timeLabelPadding;
  double _timeLabelPadding;
  set timeLabelPadding(double value) { if (_timeLabelPadding == value) return; _timeLabelPadding = value; markNeedsLayout(); }

  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) { if (_textScaler == value) return; _textScaler = value; _clearLabelCache(); markNeedsLayout(); }

  static const _minDesiredWidth = 100.0;
  @override double computeMinIntrinsicWidth(double height) => _minDesiredWidth;
  @override double computeMaxIntrinsicWidth(double height) => _minDesiredWidth;
  @override double computeMinIntrinsicHeight(double width) => _calculateDesiredHeight();
  @override double computeMaxIntrinsicHeight(double width) => _calculateDesiredHeight();
  @override bool hitTestSelf(Offset position) => true;
  @override void handleEvent(PointerEvent event, BoxHitTestEntry entry) { assert(debugHandleEvent(event, entry)); if (event is PointerDownEvent) { _drag?.addPointer(event); } }
  @override void performLayout() { size = computeDryLayout(constraints); }
  @override Size computeDryLayout(BoxConstraints constraints) { final desiredWidth = constraints.maxWidth; final desiredHeight = _calculateDesiredHeight(); final desiredSize = Size(desiredWidth, desiredHeight); return constraints.constrain(desiredSize); }

  double _calculateDesiredHeight() {
    switch (_timeLabelLocation) {
      case TimeLabelLocation.below:
      case TimeLabelLocation.above: return _heightWhenLabelsAboveOrBelow();
      case TimeLabelLocation.sides: return _heightWhenLabelsOnSides();
      default: return _heightWhenNoLabels();
    }
  }
  double _heightWhenLabelsAboveOrBelow() => _heightWhenNoLabels() + _textHeight() + _timeLabelPadding;
  double _heightWhenLabelsOnSides() => max(_heightWhenNoLabels(), _textHeight());
  double _heightWhenNoLabels() => max(2 * _thumbRadius, _barHeight);
  double _textHeight() => _leftLabelSize.height;

  @override bool get isRepaintBoundary => true;
  @override void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    switch (_timeLabelLocation) {
      case TimeLabelLocation.above:
      case TimeLabelLocation.below: _drawProgressBarWithLabelsAboveOrBelow(canvas); break;
      case TimeLabelLocation.sides: _drawProgressBarWithLabelsOnSides(canvas); break;
      default: _drawProgressBarWithoutLabels(canvas);
    }
    canvas.restore();
  }

  void _drawProgressBarWithLabelsAboveOrBelow(Canvas canvas) {
    final barWidth = size.width;
    // 获取左右文字的最大高度
    final textHeight = max(_leftLabelSize.height, _rightLabelSize.height);
    final isLabelBelow = _timeLabelLocation == TimeLabelLocation.below;
    final labelDy = isLabelBelow ? size.height - textHeight : 0.0;

    _leftTimeLabel().paint(canvas, Offset(0, labelDy));
    _rightTimeLabel().paint(canvas, Offset(size.width - _rightLabelSize.width, labelDy));
    final barAreaHeight = size.height - textHeight - _timeLabelPadding;
    final barDy = isLabelBelow ? 0.0 : textHeight + _timeLabelPadding;
    _drawProgressBar(canvas, Offset(0, barDy), Size(barWidth, barAreaHeight));
  }

  void _drawProgressBarWithLabelsOnSides(Canvas canvas) {
    final leftLabelSize = _leftLabelSize;
    final rightLabelSize = _rightLabelSize;

    // 侧边文字垂直居中
    final verticalOffset = size.height / 2 - leftLabelSize.height / 2;
    _leftTimeLabel().paint(canvas, Offset(0, verticalOffset));
    _rightTimeLabel().paint(canvas, Offset(size.width - rightLabelSize.width, verticalOffset));

    final barWidth = size.width - 2 * _defaultSidePadding - 2 * _timeLabelPadding - leftLabelSize.width - rightLabelSize.width;
    final barDx = leftLabelSize.width + _defaultSidePadding + _timeLabelPadding;

    // 直接传入画布的完整高度 size.height，由底层控制绝对垂直居中
    _drawProgressBar(canvas, Offset(barDx, 0.0), Size(barWidth, size.height));
  }

  void _drawProgressBarWithoutLabels(Canvas canvas) {
    // 无文字时，也是占据整个固定画板，让中心线绝对静止
    _drawProgressBar(canvas, Offset.zero, size);
  }

  void _drawProgressBar(Canvas canvas, Offset offset, Size localSize) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _drawBaseBar(canvas, localSize);
    _drawBufferedBar(canvas, localSize);
    _drawCurrentProgressBar(canvas, localSize);

    if (isLoading) {
      _drawMarqueeOverlay(canvas, localSize);
    }

    _drawThumb(canvas, localSize);

    canvas.restore();
  }

  void _drawMarqueeOverlay(Canvas canvas, Size localSize) {
    final capRadius = _barHeight / 2;
    final adjustedWidth = localSize.width - _barHeight;
    final progressProportion = _proportionOfTotal(_progress);

    double clipWidth;
    if (progressProportion > 0) {
      clipWidth = progressProportion * adjustedWidth + _barHeight;
    } else {
      clipWidth = localSize.width;
    }

    final double marqueeWidth = localSize.width * 0.5;
    final double totalAnimationDistance = localSize.width + marqueeWidth;
    final double startX = (totalAnimationDistance * loadingAnimationValue) - marqueeWidth;

    final radius = (_barCapShape == BarCapShape.round) ? Radius.circular(capRadius) : Radius.zero;

    final RRect clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, localSize.height / 2 - capRadius, clipWidth, _barHeight),
      radius,
    );

    canvas.save();
    canvas.clipRRect(clipRRect);

    final double luminance = progressBarColor.computeLuminance();
    final Color highlightColor = luminance > 0.5
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.8);

    final Paint marqueePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          highlightColor.withOpacity(0.0),
          highlightColor,
          highlightColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(startX, 0, marqueeWidth, localSize.height))
      ..strokeWidth = _barHeight
      ..strokeCap = (_barCapShape == BarCapShape.round) ? StrokeCap.round : StrokeCap.square;

    marqueePaint.blendMode = BlendMode.srcATop;

    canvas.drawLine(
      Offset(startX, localSize.height / 2),
      Offset(startX + marqueeWidth, localSize.height / 2),
      marqueePaint,
    );

    canvas.restore();
  }

  void _drawBaseBar(Canvas canvas, Size localSize) { _drawBar(canvas: canvas, availableSize: localSize, widthProportion: 1.0, color: baseBarColor); }
  void _drawBufferedBar(Canvas canvas, Size localSize) { _drawBar(canvas: canvas, availableSize: localSize, widthProportion: _proportionOfTotal(_buffered), color: bufferedBarColor); }
  void _drawCurrentProgressBar(Canvas canvas, Size localSize) { _drawBar(canvas: canvas, availableSize: localSize, widthProportion: _proportionOfTotal(_progress), color: progressBarColor); }

  void _drawBar({required Canvas canvas, required Size availableSize, required double widthProportion, required Color color}) {
    final strokeCap = (_barCapShape == BarCapShape.round) ? StrokeCap.round : StrokeCap.square;
    final baseBarPaint = Paint()..color = color..strokeCap = strokeCap..strokeWidth = _barHeight;
    final capRadius = _barHeight / 2;
    final adjustedWidth = availableSize.width - barHeight;
    final dx = widthProportion * adjustedWidth + capRadius;
    final startPoint = Offset(capRadius, availableSize.height / 2);
    var endPoint = Offset(dx, availableSize.height / 2);
    canvas.drawLine(startPoint, endPoint, baseBarPaint);
  }

  void _drawThumb(Canvas canvas, Size localSize) {
    final thumbPaint = Paint()..color = thumbColor;
    final barCapRadius = _barHeight / 2;
    final availableWidth = localSize.width - _barHeight;
    var thumbDx = _thumbValue * availableWidth + barCapRadius;
    if (!_thumbCanPaintOutsideBar) {
      thumbDx = thumbDx.clamp(_thumbRadius, localSize.width - _thumbRadius);
    }
    final center = Offset(thumbDx, localSize.height / 2);
    if (_userIsDraggingThumb) {
      final thumbGlowPaint = Paint()..color = thumbGlowColor;
      canvas.drawCircle(center, thumbGlowRadius, thumbGlowPaint);
    }
    canvas.drawCircle(center, thumbRadius, thumbPaint);
  }

  double _proportionOfTotal(Duration duration) {
    if (total.inMilliseconds == 0) return 0.0;
    return duration.inMilliseconds / total.inMilliseconds;
  }

  String _getTimeString(Duration time) {
    final minutes = time.inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = time.inSeconds.remainder(Duration.secondsPerMinute).toString().padLeft(2, '0');
    return time.inHours > 0 ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds" : "$minutes:$seconds";
  }

  Duration _clampDuration(Duration value) {
    if (value.isNegative) return Duration.zero;
    if (value.compareTo(_total) > 0) return _total;
    return value;
  }

  bool _labelLengthDifferent(Duration first, Duration second) {
    return (first.inMinutes < 10 && second.inMinutes >= 10) ||
        (first.inMinutes >= 10 && second.inMinutes < 10) ||
        (first.inHours == 0 && second.inHours != 0) ||
        (first.inHours != 0 && second.inHours == 0) ||
        (first.inHours < 10 && second.inHours >= 10) ||
        (first.inHours >= 10 && second.inHours < 10);
  }

  TextPainter? _cachedLeftLabel;
  Size get _leftLabelSize { _cachedLeftLabel ??= _leftTimeLabel(); return _cachedLeftLabel!.size; }
  TextPainter? _cachedRightLabel;
  Size get _rightLabelSize { _cachedRightLabel ??= _rightTimeLabel(); return _cachedRightLabel!.size; }
  void _clearLabelCache() { _cachedLeftLabel = null; _cachedRightLabel = null; }

  TextPainter _leftTimeLabel() { final text = _getTimeString(progress); return _layoutText(text); }
  TextPainter _rightTimeLabel() {
    switch (timeLabelType) {
      case TimeLabelType.totalTime: final text = _getTimeString(total); return _layoutText(text);
      case TimeLabelType.remainingTime: final remaining = total - progress; final text = '-${_getTimeString(remaining)}'; return _layoutText(text);
    }
  }
  TextPainter _layoutText(String text) {
    TextPainter textPainter = TextPainter(text: TextSpan(text: text, style: _timeLabelTextStyle), textDirection: TextDirection.ltr, textScaler: textScaler);
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter;
  }
}