import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/widgets/image_box/simple_extended_image.dart';
import '../player_layout.dart';

class PlayerCoverOverlay extends StatelessWidget {
  const PlayerCoverOverlay({
    super.key,
    required this.metrics,
    required this.expansion,
    required this.page,
    required this.coverUrl,
  });

  final PlayerLayoutMetrics metrics;
  final double expansion;
  final double page;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: metrics.coverRect(expansion: expansion, page: page),
      // The PageView below receives swipes even when they start on the cover.
      child: IgnorePointer(
        child: RepaintBoundary(
          key: const ValueKey('player-shared-cover'),
          child: SimpleExtendedImage(
            coverUrl,
            borderRadius: BorderRadius.circular(
              lerpDouble(8, 4, metrics.isPaged ? page * expansion : 0)!,
            ),
            fit: BoxFit.cover,
            loadingSize: 20,
          ),
        ),
      ),
    );
  }
}
