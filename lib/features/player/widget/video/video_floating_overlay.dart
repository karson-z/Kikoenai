import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_presentation_controller.dart';
import 'package:kikoenai/features/player/widget/video/player_video_content.dart';
import 'package:kikoenai/features/player/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/widget/video/player_video_gesture_layer.dart';
import 'package:kikoenai/features/player/widget/video/video_floating_layout.dart';

class VideoFloatingOverlay extends ConsumerWidget {
  const VideoFloatingOverlay({
    super.key,
    required this.controller,
    this.videoSurface = const VideoSurface(),
  });

  final VideoPresentationController controller;
  final Widget videoSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final isFullScreen = ref.watch(mainScaffoldProvider).isFullScreen;
    if (!state.isCurrentVideoView) return const SizedBox.shrink();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final layout = VideoFloatingLayout(
              size: constraints.biggest,
              padding: MediaQuery.paddingOf(context),
              aspectRatio: _aspectRatio(
                state.videoWidth,
                state.videoHeight,
                state.videoRotate,
              ),
            );
            final floatingRect = layout.resolve(controller);
            final progress = isFullScreen ? 1.0 : controller.progress;
            final rect = Rect.lerp(
              floatingRect,
              Offset.zero & layout.size,
              progress,
            )!;
            final floatingInteractive =
                !isFullScreen && controller.progress == 0;
            final hidden = floatingInteractive && controller.isFloatingHidden;
            final hitRect = layout.hitRect(rect, hidden: hidden);

            return Stack(
              fit: StackFit.expand,
              // Only the part inside the application's content is painted.
              clipBehavior: Clip.hardEdge,
              children: [
                if (!isFullScreen && controller.progress > 0.01)
                  GestureDetector(
                    onTap: controller.collapse,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35 * progress),
                    ),
                  ),
                Positioned.fromRect(
                  key: const ValueKey('floating-video-stage'),
                  rect: hitRect,
                  child: _VideoStage(
                    videoRect: rect.shift(-hitRect.topLeft),
                    videoSurface: videoSurface,
                    expanded: isFullScreen || controller.progress > 0.98,
                    floatingInteractive: floatingInteractive,
                    hidden: hidden,
                    onTap: () => _tapFloating(layout),
                    onCollapse: controller.collapse,
                    onDragStart: () => controller.beginFloatingInteraction(
                      layout.resolve(controller).topLeft - layout.base.topLeft,
                    ),
                    onDrag: (delta) {
                      if (!controller.isFloatingDragging) return;
                      final next = layout.clamp(
                        layout.resolve(controller).shift(delta),
                        allowOverflow: true,
                      );
                      controller.setFloatingOffset(
                        next.topLeft - layout.base.topLeft,
                      );
                    },
                    onDragEnd: (distance, velocity, intent, cancelled) =>
                        _settleFloating(
                          layout,
                          distance,
                          velocity,
                          intent,
                          cancelled,
                        ),
                    radius: 14 * (1 - progress),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _aspectRatio(int width, int height, int rotate) {
    if (width <= 0 || height <= 0) return 16 / 9;
    final sideways = rotate == 90 || rotate == 270;
    final effectiveWidth = sideways ? height : width;
    final effectiveHeight = sideways ? width : height;
    return effectiveWidth / effectiveHeight;
  }

  void _tapFloating(VideoFloatingLayout layout) {
    final side = controller.dockedSide;
    if (controller.isFloatingHidden && side != null) {
      // The first tap on the edge peek only restores the floating window.
      _animateToSide(layout, side, hidden: false, restoring: true);
    } else if (!controller.isFloatingSettling) {
      controller.expand();
    }
  }

  void _settleFloating(
    VideoFloatingLayout layout,
    Offset distance,
    Offset velocity,
    double horizontalIntent,
    bool cancelled,
  ) {
    if (!controller.isFloatingDragging) return;
    final rect = layout.resolve(controller);
    final side = layout.nearestSide(rect);
    final hidden =
        !cancelled &&
        layout.shouldHide(
          rect: rect,
          side: side,
          dragDistance: distance,
          velocity: velocity,
          horizontalIntent: horizontalIntent,
        );
    _animateToSide(layout, side, hidden: hidden);
  }

  void _animateToSide(
    VideoFloatingLayout layout,
    VideoFloatingDock side, {
    required bool hidden,
    bool restoring = false,
  }) {
    final current = layout.resolve(controller);
    // Rebase on the visible position so a resized or interrupted animation
    // cannot jump to a stale stored offset on the first frame.
    controller.setFloatingOffset(current.topLeft - layout.base.topLeft);
    controller.animateFloatingOffset(
      offset: Offset(
        layout.dockLeft(side, hidden: hidden) - layout.base.left,
        current.top - layout.base.top,
      ),
      dockedSide: side,
      hidden: hidden,
      duration: Duration(milliseconds: hidden || restoring ? 180 : 220),
      curve: hidden ? Curves.fastOutSlowIn : Curves.easeOutCubic,
    );
  }
}

class _VideoStage extends StatefulWidget {
  const _VideoStage({
    required this.videoRect,
    required this.videoSurface,
    required this.expanded,
    required this.floatingInteractive,
    required this.hidden,
    required this.onTap,
    required this.onCollapse,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.radius,
  });

  final Rect videoRect;
  final Widget videoSurface;
  final bool expanded;
  final bool floatingInteractive;
  final bool hidden;
  final VoidCallback onTap;
  final VoidCallback onCollapse;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDrag;
  final void Function(
    Offset distance,
    Offset velocity,
    double intent,
    bool cancelled,
  )
  onDragEnd;
  final double radius;

  @override
  State<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<_VideoStage> {
  Offset? _lastDragPosition;
  Offset _dragDistance = Offset.zero;
  double _horizontalIntent = 0;
  bool _dragWasCancelled = false;

  void _startDrag(DragStartDetails details) {
    _lastDragPosition = details.globalPosition;
    _dragDistance = Offset.zero;
    _horizontalIntent = 0;
    _dragWasCancelled = false;
    widget.onDragStart();
  }

  void _updateDrag(DragUpdateDetails details) {
    final previous = _lastDragPosition;
    _lastDragPosition = details.globalPosition;
    if (previous == null) return;
    // Fresh pointer positions avoid accumulated overscroll at a boundary.
    final delta = details.globalPosition - previous;
    _dragDistance += delta;
    if (delta.dx != 0) {
      _horizontalIntent = _horizontalIntent.sign == delta.dx.sign
          ? _horizontalIntent + delta.dx
          : delta.dx;
    }
    widget.onDrag(delta);
  }

  void _endDrag(Offset velocity, {bool cancelled = false}) {
    if (_lastDragPosition == null) return;
    _lastDragPosition = null;
    widget.onDragEnd(
      _dragDistance,
      velocity,
      _horizontalIntent,
      cancelled || _dragWasCancelled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.hidden ? '显示悬浮视频' : null,
      button: widget.hidden,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: widget.floatingInteractive ? widget.onTap : null,
        onPanStart: widget.floatingInteractive ? _startDrag : null,
        onPanUpdate: widget.floatingInteractive ? _updateDrag : null,
        onPanEnd: widget.floatingInteractive
            ? (details) => _endDrag(details.velocity.pixelsPerSecond)
            : null,
        onPanCancel: widget.floatingInteractive
            ? () => _endDrag(Offset.zero, cancelled: true)
            : null,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          // An accepted pan reports onPanEnd even for PointerCancelEvent.
          // Record cancellation before the event reaches its recognizer.
          onPointerCancel: (_) => _dragWasCancelled = true,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: widget.videoRect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: Material(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.videoSurface,
                        if (widget.expanded) ...[
                          const VideoGestureLayer(child: SizedBox.expand()),
                          PlayerVideoControlsOverlay(
                            onCollapse: widget.onCollapse,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
