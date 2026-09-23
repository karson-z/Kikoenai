import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry shared by the actual pages and their floating cover.
/// All rectangles except the playback slots are in PlayerView coordinates.
class PlayerLayoutMetrics {
  PlayerLayoutMetrics({
    required this.size,
    required EdgeInsets padding,
    required TextScaler textScaler,
    required double minHeight,
  }) {
    isWideScreen = size.width >= wideBreakpoint;
    final safeWidth = math.max(0.0, size.width - padding.horizontal);
    topBar = Rect.fromLTWH(padding.left, padding.top + 8, safeWidth, 60);
    content = Rect.fromLTWH(
      padding.left,
      topBar.bottom + 8,
      safeWidth,
      math.max(0.0, size.height - topBar.bottom - 20 - padding.bottom),
    );
    final columnWidth = isWideScreen ? content.width / 2 : content.width;
    playbackSize = Size(columnWidth, content.height);

    // Start with proportions of the whole page. Reserve readable text and
    // usable controls before giving the remaining space back to the cover.
    final heights = _allocateHeights(content.height, [
      0,
      (textScaler.scale(22) + textScaler.scale(16)) * 1.3 + 12,
      math.max(48, textScaler.scale(12) * 1.3 + 24),
      70,
      48,
    ]);
    var y = 0.0;
    Rect slot(double height) {
      final rect = Rect.fromLTWH(0, y, columnWidth, height);
      y += height;
      return rect;
    }

    coverSlot = slot(heights[0]);
    infoSlot = slot(heights[1]);
    progressSlot = slot(heights[2]);
    controlsSlot = slot(heights[3]);
    volumeSlot = slot(heights[4]);

    final coverSize = math.max(
      0.0,
      math.min(
        math.min(columnWidth * 0.82, isWideScreen ? 350.0 : 450.0),
        coverSlot.height - 12,
      ),
    );
    albumCover = Rect.fromCenter(
      center: coverSlot.center + content.topLeft,
      width: coverSize,
      height: coverSize,
    );
    lyricsHeaderHeight = math.max(
      60,
      (textScaler.scale(16) + textScaler.scale(12)) * 1.3 + 12,
    );
    lyricsCover = Rect.fromLTWH(
      content.left + lyricsCoverLeft,
      content.top + (lyricsHeaderHeight - lyricsCoverSize) / 2,
      lyricsCoverSize,
      lyricsCoverSize,
    );
    final miniCoverSize = math.max(0.0, minHeight - 10);
    collapsedCover = Rect.fromLTWH(12, 5, miniCoverSize, miniCoverSize);
  }

  static const wideBreakpoint = 800.0;
  static const lyricsCoverLeft = 24.0;
  static const lyricsCoverSize = 50.0;
  static const _weights = [0.50, 0.14, 0.10, 0.16, 0.10];

  final Size size;
  late final bool isWideScreen;
  late final Rect topBar;
  late final Rect content;
  late final Size playbackSize;
  late final Rect coverSlot;
  late final Rect infoSlot;
  late final Rect progressSlot;
  late final Rect controlsSlot;
  late final Rect volumeSlot;
  late final Rect albumCover;
  late final Rect lyricsCover;
  late final Rect collapsedCover;
  late final double lyricsHeaderHeight;

  Rect coverRect({required double expansion, required double page}) {
    final expanded = isWideScreen
        ? albumCover
        : Rect.lerp(albumCover, lyricsCover, page.clamp(0.0, 1.0))!;
    return Rect.lerp(collapsedCover, expanded, expansion.clamp(0.0, 1.0))!;
  }

  static List<double> _allocateHeights(double height, List<double> minimums) {
    final result = List<double>.filled(_weights.length, 0);
    final pending = {for (var i = 0; i < _weights.length; i++) i};
    final minimumTotal = minimums.fold<double>(0, (sum, value) => sum + value);
    // Only reached for extreme window heights: keep every region in bounds.
    if (minimumTotal > height) {
      return minimums.map((value) => value * height / minimumTotal).toList();
    }
    var remaining = height;
    while (pending.isNotEmpty) {
      final weight = pending.fold<double>(0, (sum, i) => sum + _weights[i]);
      final constrained = pending
          .where((i) => remaining * _weights[i] / weight < minimums[i])
          .toList();
      if (constrained.isEmpty) {
        for (final i in pending) {
          result[i] = remaining * _weights[i] / weight;
        }
        break;
      }
      for (final i in constrained) {
        result[i] = minimums[i];
        remaining -= result[i];
        pending.remove(i);
      }
    }
    return result;
  }
}
