import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PlayerLayoutMode { paged, sideBySide, stacked }

/// Geometry shared by the actual pages and their floating cover.
/// Playback slots are local to [playbackViewport]; other rectangles are in
/// PlayerView coordinates. The PageView still fills [content] on narrow screens.
class PlayerLayoutMetrics {
  PlayerLayoutMetrics({
    required this.size,
    required EdgeInsets padding,
    required TextScaler textScaler,
    required double minHeight,
  }) {
    final safeWidth = math.max(0.0, size.width - padding.horizontal);
    topBar = Rect.fromLTWH(padding.left, padding.top + 8, safeWidth, 60);
    content = Rect.fromLTWH(
      padding.left,
      topBar.bottom + 8,
      safeWidth,
      math.max(0.0, size.height - topBar.bottom - 20 - padding.bottom),
    );
    final minimums = <double>[
      0,
      (textScaler.scale(22) + textScaler.scale(16)) * 1.3 + 12,
      math.max(48, textScaler.scale(12) * 1.3 + 24),
      70,
      48,
    ];
    final controlMaximums = <double>[
      minimums[1] + 24,
      minimums[2] + 16,
      minimums[3] + 18,
      minimums[4] + 16,
    ];
    final minimumPlaybackWidth = math.max(320.0, textScaler.scale(22) * 8 + 56);
    final minimumLyricsWidth = math.max(360.0, textScaler.scale(20) * 12 + 48);
    final minimumLyricsHeight = math.max(360.0, textScaler.scale(20) * 10);
    final controlHeight = _sum(controlMaximums);
    final compactHeight = math.max(compactCoverLimit, controlHeight);
    final innerWidth = math.max(0.0, content.width - paneInset * 2);
    final sideWidth = math.min(innerWidth, maxSideBySideWidth);
    final stackedWidth = math.min(innerWidth, maxStackedWidth);

    // Width alone cannot distinguish a desktop window from a tall portrait
    // display. Check both the shape and the space needed by each content region.
    final canShowSideBySide =
        content.width >= wideBreakpoint &&
        safeWidth >= math.max(0.0, size.height - padding.vertical) * 1.2 &&
        minimumPlaybackWidth <= maxPlaybackWidth &&
        minimumLyricsWidth <= maxLyricsWidth &&
        sideWidth >= minimumPlaybackWidth + paneGap + minimumLyricsWidth &&
        content.height >= math.max(_sum(minimums) + 120, minimumLyricsHeight);
    final canStack =
        content.width >= stackedBreakpoint &&
        minimumPlaybackWidth <= maxPlaybackWidth &&
        minimumLyricsWidth <= maxLyricsWidth &&
        stackedWidth >= 180 + paneGap + minimumPlaybackWidth &&
        stackedWidth >= minimumLyricsWidth &&
        content.height >= compactHeight + paneGap + minimumLyricsHeight;
    mode = canShowSideBySide
        ? PlayerLayoutMode.sideBySide
        : canStack
        ? PlayerLayoutMode.stacked
        : PlayerLayoutMode.paged;

    switch (mode) {
      case PlayerLayoutMode.paged:
        playbackViewport = content;
        lyricsViewport = content;
      case PlayerLayoutMode.sideBySide:
        final stage = Rect.fromCenter(
          center: content.center,
          width: sideWidth,
          height: math.min(content.height, maxLyricsHeight),
        );
        final playbackWidth = (stage.width - paneGap) * 0.44;
        final columnWidth = playbackWidth
            .clamp(
              minimumPlaybackWidth,
              math.min(
                maxPlaybackWidth,
                stage.width - paneGap - minimumLyricsWidth,
              ),
            )
            .toDouble();
        playbackViewport = Rect.fromLTWH(
          stage.left,
          stage.top,
          columnWidth,
          stage.height,
        );
        lyricsViewport = Rect.fromLTRB(
          playbackViewport.right + paneGap,
          stage.top,
          stage.right,
          stage.bottom,
        );
      case PlayerLayoutMode.stacked:
        final lyricsHeight = math.min(
          maxLyricsHeight,
          content.height - compactHeight - paneGap,
        );
        final stage = Rect.fromCenter(
          center: content.center,
          width: stackedWidth,
          height: compactHeight + paneGap + lyricsHeight,
        );
        playbackViewport = Rect.fromLTWH(
          stage.left,
          stage.top,
          stage.width,
          compactHeight,
        );
        lyricsViewport = Rect.fromLTRB(
          stage.left,
          playbackViewport.bottom + paneGap,
          stage.right,
          stage.bottom,
        );
    }

    if (mode == PlayerLayoutMode.stacked) {
      final coverWidth = math.min(
        compactCoverLimit,
        math.min(
          (playbackViewport.width - paneGap) * 0.36,
          playbackViewport.width - paneGap - minimumPlaybackWidth,
        ),
      );
      coverSlot = Rect.fromLTWH(0, 0, coverWidth, compactHeight);
      var y = (compactHeight - controlHeight) / 2;
      Rect slot(double height) {
        final rect = Rect.fromLTWH(
          coverWidth + paneGap,
          y,
          playbackViewport.width - coverWidth - paneGap,
          height,
        );
        y += height;
        return rect;
      }

      infoSlot = slot(controlMaximums[0]);
      progressSlot = slot(controlMaximums[1]);
      controlsSlot = slot(controlMaximums[2]);
      volumeSlot = slot(controlMaximums[3]);
    } else {
      final blockWidth = math.min(playbackViewport.width, maxPlaybackWidth);
      final maximums = <double>[
        math.min(blockWidth * 0.82, isPaged ? 450.0 : 350.0) + 24,
        ...controlMaximums,
      ];
      final blockHeight = math.min(playbackViewport.height, _sum(maximums));
      final heights = _allocateHeights(blockHeight, minimums, maximums);
      final x = (playbackViewport.width - blockWidth) / 2;
      var y = (playbackViewport.height - blockHeight) / 2;
      Rect slot(double height) {
        final rect = Rect.fromLTWH(x, y, blockWidth, height);
        y += height;
        return rect;
      }

      coverSlot = slot(heights[0]);
      infoSlot = slot(heights[1]);
      progressSlot = slot(heights[2]);
      controlsSlot = slot(heights[3]);
      volumeSlot = slot(heights[4]);
    }

    final coverSize = mode == PlayerLayoutMode.stacked
        ? coverSlot.width
        : math.max(
            0.0,
            math.min(
              math.min(coverSlot.width * 0.82, isPaged ? 450.0 : 350.0),
              coverSlot.height - 12,
            ),
          );
    albumCover = Rect.fromCenter(
      center: coverSlot.center + playbackViewport.topLeft,
      width: coverSize,
      height: coverSize,
    );
    lyricsFrame = Rect.fromCenter(
      center: lyricsViewport.center,
      width: math.min(lyricsViewport.width, maxLyricsWidth),
      height: math.min(lyricsViewport.height, maxLyricsHeight),
    );
    lyricsHeaderHeight = math.max(
      60,
      (textScaler.scale(16) + textScaler.scale(12)) * 1.3 + 12,
    );
    lyricsCover = Rect.fromLTWH(
      lyricsFrame.left + lyricsCoverLeft,
      lyricsFrame.top + (lyricsHeaderHeight - lyricsCoverSize) / 2,
      lyricsCoverSize,
      lyricsCoverSize,
    );
    final miniCoverSize = math.max(0.0, minHeight - 10);
    collapsedCover = Rect.fromLTWH(12, 5, miniCoverSize, miniCoverSize);
  }

  static const wideBreakpoint = 800.0;
  static const stackedBreakpoint = 720.0;
  static const paneInset = 24.0;
  static const paneGap = 32.0;
  static const maxPlaybackWidth = 560.0;
  static const maxLyricsWidth = 760.0;
  static const maxLyricsHeight = 900.0;
  static const compactCoverLimit = 280.0;
  static const maxSideBySideWidth = maxPlaybackWidth + paneGap + maxLyricsWidth;
  static const maxStackedWidth = compactCoverLimit + paneGap + maxPlaybackWidth;
  static const lyricsCoverLeft = 24.0;
  static const lyricsCoverSize = 50.0;
  static const _weights = [0.50, 0.14, 0.10, 0.16, 0.10];

  final Size size;
  late final PlayerLayoutMode mode;
  bool get isPaged => mode == PlayerLayoutMode.paged;
  late final Rect topBar;
  late final Rect content;
  late final Rect playbackViewport;
  late final Rect lyricsViewport;
  late final Rect lyricsFrame;
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
    final expanded = isPaged
        ? Rect.lerp(albumCover, lyricsCover, page.clamp(0.0, 1.0))!
        : albumCover;
    return Rect.lerp(collapsedCover, expanded, expansion.clamp(0.0, 1.0))!;
  }

  static double _sum(List<double> values) =>
      values.fold(0.0, (sum, value) => sum + value);

  // Keep proportional regions on short screens, while preventing tall windows
  // from inflating the gaps between fixed-size text, sliders and buttons.
  static List<double> _allocateHeights(
    double height,
    List<double> minimums,
    List<double> maximums,
  ) {
    final minimumTotal = _sum(minimums);
    // Only reached for extreme window heights: keep every region in bounds.
    if (minimumTotal > height) {
      return minimums.map((value) => value * height / minimumTotal).toList();
    }
    if (height >= _sum(maximums)) return maximums;

    List<double> scaled(double factor) => [
      for (var i = 0; i < _weights.length; i++)
        (_weights[i] * factor).clamp(minimums[i], maximums[i]).toDouble(),
    ];
    // Solve for a common scale with both bounds applied together. Freezing a
    // minimum first can leave unused space after another region hits its cap.
    var low = 0.0;
    var high = 0.0;
    for (var i = 0; i < _weights.length; i++) {
      high = math.max(high, maximums[i] / _weights[i]);
    }
    for (var iteration = 0; iteration < 40; iteration++) {
      final middle = (low + high) / 2;
      if (_sum(scaled(middle)) > height) {
        high = middle;
      } else {
        low = middle;
      }
    }
    return scaled(low);
  }
}
