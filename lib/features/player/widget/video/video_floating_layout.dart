import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kikoenai/features/player/provider/video_presentation_controller.dart';

/// Geometry uses the overlay's actual bounds. Hidden windows dock against the
/// content edge; fully visible windows respect the safe area and a 12px margin.
class VideoFloatingLayout {
  VideoFloatingLayout({
    required this.size,
    required this.padding,
    required double aspectRatio,
  }) {
    final maxWidth = math.max(0.0, size.width - padding.horizontal - 24);
    final maxHeight = math.min(
      size.height * 0.42,
      math.max(0.0, size.height - padding.vertical - 24),
    );
    final landscapeWidth = (size.width * 0.58).clamp(220.0, 360.0).toDouble();
    final double width;
    final double height;
    if (aspectRatio < 1) {
      // Rotate the standard 16:9 frame; source ratios only affect image fit.
      height = math.min(landscapeWidth, math.min(maxHeight, maxWidth * 16 / 9));
      width = height * 9 / 16;
    } else {
      width = math.min(
        landscapeWidth,
        math.min(maxWidth, maxHeight * aspectRatio),
      );
      height = width / aspectRatio;
    }
    base = Rect.fromLTWH(
      size.width - padding.right - 16 - width,
      size.height - padding.bottom - 16 - height,
      width,
      height,
    );
  }

  final Size size;
  final EdgeInsets padding;
  late final Rect base;

  double dockLeft(VideoFloatingDock side, {required bool hidden}) {
    if (hidden) {
      return side == VideoFloatingDock.left
          ? -base.width * 0.9
          : size.width - base.width * 0.1;
    }
    return side == VideoFloatingDock.left
        ? padding.left + 12
        : math.max(
            padding.left + 12,
            size.width - padding.right - 12 - base.width,
          );
  }

  Rect clamp(Rect rect, {required bool allowOverflow}) {
    final minLeft = dockLeft(VideoFloatingDock.left, hidden: allowOverflow);
    final maxLeft = dockLeft(VideoFloatingDock.right, hidden: allowOverflow);
    final minTop = padding.top + 12;
    final maxTop = math.max(
      minTop,
      size.height - padding.bottom - 12 - rect.height,
    );
    return Rect.fromLTWH(
      rect.left.clamp(minLeft, maxLeft).toDouble(),
      rect.top.clamp(minTop, maxTop).toDouble(),
      rect.width,
      rect.height,
    );
  }

  Rect resolve(VideoPresentationController controller) {
    var rect = base.shift(controller.floatingOffset);
    final side = controller.dockedSide;
    if (side != null &&
        !controller.isFloatingSettling &&
        !controller.isFloatingDragging) {
      // Recompute from the side after a resize, rather than retaining a stale
      // pixel coordinate that could strand the window outside the content.
      rect = Rect.fromLTWH(
        dockLeft(side, hidden: controller.isFloatingHidden),
        rect.top,
        rect.width,
        rect.height,
      );
    }
    return clamp(
      rect,
      allowOverflow:
          controller.isFloatingHidden ||
          controller.isFloatingDragging ||
          controller.isFloatingSettling,
    );
  }

  VideoFloatingDock nearestSide(Rect rect) => rect.center.dx < size.width / 2
      ? VideoFloatingDock.left
      : VideoFloatingDock.right;

  bool shouldHide({
    required Rect rect,
    required VideoFloatingDock side,
    required Offset dragDistance,
    required Offset velocity,
    required double horizontalIntent,
  }) {
    final sign = side == VideoFloatingDock.left ? -1.0 : 1.0;
    // A deliberate inward correction overrides earlier outward movement.
    if (horizontalIntent * sign <= -24) return false;
    final overflow = side == VideoFloatingDock.left
        ? math.max(0.0, -rect.left)
        : math.max(0.0, rect.right - size.width);
    final outwardFling =
        velocity.dx * sign >= 700 &&
        velocity.dx.abs() > velocity.dy.abs() * 1.2;
    final edgeDistance = side == VideoFloatingDock.left
        ? rect.left
        : size.width - rect.right;
    final deliberateEdgeDrag =
        edgeDistance <= size.width * 0.12 &&
        dragDistance.dx * sign >= math.max(32, rect.width * 0.15) &&
        horizontalIntent * sign >= 24;
    return overflow >= math.max(1, rect.width * 0.2) ||
        outwardFling ||
        deliberateEdgeDrag;
  }

  Rect hitRect(Rect rect, {required bool hidden}) {
    if (!hidden) return rect;
    final visibleWidth =
        math.min(size.width, rect.right) - math.max(0, rect.left);
    final hitWidth = math.min(44.0, size.width);
    if (visibleWidth >= hitWidth) return rect;
    final strip = Rect.fromLTWH(
      nearestSide(rect) == VideoFloatingDock.left ? 0 : size.width - hitWidth,
      rect.top,
      hitWidth,
      rect.height,
    );
    return rect.expandToInclude(strip);
  }
}
