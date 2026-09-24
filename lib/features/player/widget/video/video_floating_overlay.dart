import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_presentation_controller.dart';
import 'package:kikoenai/features/player/widget/video/player_video_content.dart';
import 'package:kikoenai/features/player/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/widget/video/player_video_gesture_layer.dart';

class VideoFloatingOverlay extends ConsumerWidget {
  const VideoFloatingOverlay({super.key, required this.controller});

  final VideoPresentationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final isFullScreen = ref.watch(mainScaffoldProvider).isFullScreen;
    if (!state.isCurrentVideoView) return const SizedBox.shrink();

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final padding = MediaQuery.paddingOf(context);
          final expandedRect = Offset.zero & size;
          final floatingRect = _floatingRect(
            size: size,
            padding: padding,
            aspectRatio: _aspectRatio(
                state.videoWidth, state.videoHeight, state.videoRotate),
            offset: controller.floatingOffset,
          );
          final progress = isFullScreen
              ? 1.0
              : Curves.easeOutCubic.transform(controller.progress);
          final rect = Rect.lerp(floatingRect, expandedRect, progress)!;
          final isExpanded = isFullScreen || controller.progress > 0.98;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (!isFullScreen && controller.progress > 0.01)
                GestureDetector(
                  onTap: controller.collapse,
                  child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35 * progress)),
                ),
              Positioned.fromRect(
                rect: rect,
                child: _VideoStage(
                  expanded: isExpanded,
                  onExpand: controller.expand,
                  onCollapse: controller.collapse,
                  onDrag: (delta) => _moveFloating(
                    controller,
                    delta,
                    size,
                    padding,
                    floatingRect,
                  ),
                  radius: _lerpRadius(14, 0, progress),
                ),
              ),
            ],
          );
        },
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

  static Rect _floatingRect({
    required Size size,
    required EdgeInsets padding,
    required double aspectRatio,
    required Offset offset,
  }) {
    final width = math.min(360.0, math.max(220.0, size.width * 0.58));
    final height = math.min(width / aspectRatio, size.height * 0.42);
    final right = 16.0;
    final bottom = padding.bottom + 16.0;
    final left = size.width - right - width + offset.dx;
    final top = size.height - bottom - height + offset.dy;
    return Rect.fromLTWH(left, top, width, height);
  }

  static void _moveFloating(
    VideoPresentationController controller,
    Offset delta,
    Size size,
    EdgeInsets padding,
    Rect base,
  ) {
    final next = controller.floatingOffset + delta;
    final minDx = 12 - base.left;
    final maxDx = size.width - 12 - base.right;
    final minDy = padding.top + 12 - base.top;
    final maxDy = size.height - padding.bottom - 12 - base.bottom;
    controller.setFloatingOffset(
      Offset(
        next.dx.clamp(minDx, maxDx).toDouble(),
        next.dy.clamp(minDy, maxDy).toDouble(),
      ),
    );
  }

  static double _lerpRadius(double a, double b, double t) =>
      (a + (b - a) * t).clamp(0, double.infinity);
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onDrag,
    required this.radius,
  });

  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final ValueChanged<Offset> onDrag;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: Colors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: expanded ? null : onExpand,
          onPanUpdate: expanded ? null : (details) => onDrag(details.delta),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const VideoSurface(),
              if (expanded) ...[
                const VideoGestureLayer(child: SizedBox.expand()),
                PlayerVideoControlsOverlay(onCollapse: onCollapse),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
