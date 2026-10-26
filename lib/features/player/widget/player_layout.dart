import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PlayerLayoutMode { paged, compactSideBySide, sideBySide, sharedControls }

/// Geometry shared by the actual pages and their floating cover.
/// Playback slots (including the shared bottom dock) are local to
/// [playbackViewport]; other rectangles are in PlayerView coordinates.
/// The PageView still fills [content] on narrow screens.
class PlayerLayoutMetrics {
  PlayerLayoutMetrics({
    required this.size,
    required EdgeInsets padding,
    required TextScaler textScaler,
    required double minHeight,
    double collapsedLeft = 12,
    bool isPhone = false,
    bool isTablet = false,
  }) {
    final phoneLandscape = isPhone && size.width > size.height;
    final safeWidth = math.max(0.0, size.width - padding.horizontal);
    topBar = Rect.fromLTWH(
      padding.left,
      padding.top + 8,
      safeWidth,
      phoneLandscape ? 44 : 60,
    );
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
    final minimumPlaybackWidth = math.max(244.0, textScaler.scale(22) * 8 + 56);
    final minimumLyricsWidth = math.max(320.0, textScaler.scale(20) * 12 + 48);
    final minimumLyricsHeight = math.max(360.0, textScaler.scale(20) * 10);
    final innerWidth = math.max(0.0, content.width - paneInset * 2);
    final stageWidth = math.min(innerWidth, maxSideBySideWidth);
    final dockControlsHeight =
        (content.height - minimumLyricsHeight - paneGap - controlMaximums[1])
            .clamp(minimums[3], controlMaximums[2])
            .toDouble();
    final dockHeight = controlMaximums[1] + dockControlsHeight;

    final tabletPortrait = isTablet && size.height > size.width;
    final canShowSharedControls =
        !isPhone &&
        tabletPortrait &&
        content.width >= wideBreakpoint &&
        minimumPlaybackWidth <= maxPlaybackWidth &&
        minimumLyricsWidth <= maxLyricsWidth &&
        stageWidth >= minimumPlaybackWidth + paneGap + minimumLyricsWidth &&
        content.height >= minimumLyricsHeight + paneGap + dockHeight;
    final canShowSideBySide =
        !isPhone &&
        !tabletPortrait &&
        content.width >= wideBreakpoint &&
        minimumPlaybackWidth <= maxPlaybackWidth &&
        minimumLyricsWidth <= maxLyricsWidth &&
        stageWidth >=
            math.max(320, minimumPlaybackWidth) +
                paneGap +
                minimumLyricsWidth &&
        content.height >= math.max(_sum(minimums) + 120, minimumLyricsHeight);
    final compactWidth = math.max(0.0, content.width - compactPaneInset * 2);
    final compactInfoHeight =
        (textScaler.scale(18) + textScaler.scale(12)) * 1.3 + 16;
    final compactHeaderMinimum = math.max(80.0, compactInfoHeight);
    final compactProgressHeight = minimums[2];
    final compactControlsHeight = minimums[3];
    final compactVolumeHeight = minimums[4];
    final compactTailHeight =
        compactProgressHeight + compactControlsHeight + compactVolumeHeight;
    final compactPlaybackMinimum = math.max(
      300.0,
      textScaler.scale(18) * 8 + 80,
    );
    final compactLyricsMinimum = math.max(260.0, textScaler.scale(20) * 7 + 32);
    final canShowCompactSideBySide =
        phoneLandscape &&
        compactWidth >=
            compactPlaybackMinimum + compactPaneGap + compactLyricsMinimum &&
        content.height >= compactHeaderMinimum + compactTailHeight;
    mode = canShowCompactSideBySide
        ? PlayerLayoutMode.compactSideBySide
        : canShowSharedControls
        ? PlayerLayoutMode.sharedControls
        : canShowSideBySide
        ? PlayerLayoutMode.sideBySide
        : PlayerLayoutMode.paged;

    if (isCompactSplit) {
      final columnWidth = ((compactWidth - compactPaneGap) * 0.46)
          .clamp(
            compactPlaybackMinimum,
            compactWidth - compactPaneGap - compactLyricsMinimum,
          )
          .toDouble();
      playbackViewport = Rect.fromLTWH(
        content.left + compactPaneInset,
        content.top,
        columnWidth,
        content.height,
      );
      lyricsViewport = Rect.fromLTWH(
        playbackViewport.right + compactPaneGap,
        content.top,
        compactWidth - columnWidth - compactPaneGap,
        content.height,
      );
      final headerHeight = math.min(
        math.max(112.0, compactHeaderMinimum),
        content.height - compactTailHeight,
      );
      var y = (content.height - headerHeight - compactTailHeight) / 2;
      final coverSize = math.min(112.0, headerHeight);
      coverSlot = Rect.fromLTWH(
        0,
        y + (headerHeight - coverSize) / 2,
        coverSize,
        coverSize,
      );
      infoSlot = Rect.fromLTWH(
        coverSize + 16,
        y,
        columnWidth - coverSize - 16,
        headerHeight,
      );
      y += headerHeight;
      progressSlot = Rect.fromLTWH(0, y, columnWidth, compactProgressHeight);
      y += compactProgressHeight;
      controlsSlot = Rect.fromLTWH(0, y, columnWidth, compactControlsHeight);
      y += compactControlsHeight;
      volumeSlot = Rect.fromLTWH(0, y, columnWidth, compactVolumeHeight);
    } else if (hasSharedControls) {
      playbackViewport = Rect.fromCenter(
        center: content.center,
        width: stageWidth,
        height: math.min(
          content.height,
          maxLyricsHeight + paneGap + dockHeight,
        ),
      );
      final columnWidth = ((stageWidth - paneGap) * 0.4)
          .clamp(
            minimumPlaybackWidth,
            math.min(
              maxPlaybackWidth,
              stageWidth - paneGap - minimumLyricsWidth,
            ),
          )
          .toDouble();
      final readingHeight = playbackViewport.height - paneGap - dockHeight;
      lyricsViewport = Rect.fromLTWH(
        playbackViewport.left + columnWidth + paneGap,
        playbackViewport.top,
        stageWidth - columnWidth - paneGap,
        readingHeight,
      );
      final infoHeight = controlMaximums[0];
      final coverSize = math.min(
        math.min(columnWidth * 0.9, 350.0),
        readingHeight - infoHeight - 24,
      );
      final blockTop = math.min(
        (readingHeight - coverSize) / 2 - 12,
        readingHeight - coverSize - 24 - infoHeight,
      );
      coverSlot = Rect.fromLTWH(0, blockTop, columnWidth, coverSize);
      infoSlot = Rect.fromLTWH(
        0,
        coverSlot.bottom + 24,
        columnWidth,
        infoHeight,
      );
      progressSlot = Rect.fromLTWH(
        0,
        readingHeight + paneGap,
        stageWidth,
        controlMaximums[1],
      );
      final controlsWidth = (stageWidth * 0.52).clamp(320.0, 420.0).toDouble();
      controlsSlot = Rect.fromLTWH(
        0,
        progressSlot.bottom,
        controlsWidth,
        dockControlsHeight,
      );
      volumeSlot = Rect.fromLTWH(
        controlsSlot.right + 24,
        controlsSlot.top,
        stageWidth - controlsWidth - 24,
        controlsSlot.height,
      );
    } else {
      if (isPaged) {
        playbackViewport = content;
        lyricsViewport = content;
      } else {
        final stage = Rect.fromCenter(
          center: content.center,
          width: stageWidth,
          height: math.min(content.height, maxLyricsHeight),
        );
        final columnWidth = ((stageWidth - paneGap) * 0.4)
            .clamp(
              math.max(320.0, minimumPlaybackWidth),
              math.min(
                maxPlaybackWidth,
                stageWidth - paneGap - minimumLyricsWidth,
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
      }
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

    final coverSize = hasSharedControls || isCompactSplit
        ? coverSlot.height
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
    collapsedCover = Rect.fromLTWH(
      collapsedLeft,
      5,
      miniCoverSize,
      miniCoverSize,
    );
  }

  static const wideBreakpoint = 720.0;
  static const paneInset = 24.0;
  static const compactPaneInset = 16.0;
  static const compactPaneGap = 24.0;
  static const paneGap = 32.0;
  static const maxPlaybackWidth = 560.0;
  static const maxLyricsWidth = 760.0;
  static const maxLyricsHeight = 900.0;
  static const maxSideBySideWidth = maxPlaybackWidth + paneGap + maxLyricsWidth;
  static const lyricsCoverLeft = 24.0;
  static const lyricsCoverSize = 50.0;
  static const _weights = [0.50, 0.14, 0.10, 0.16, 0.10];

  final Size size;
  late final PlayerLayoutMode mode;
  bool get isPaged => mode == PlayerLayoutMode.paged;
  bool get isCompactSplit => mode == PlayerLayoutMode.compactSideBySide;
  bool get hasSharedControls => mode == PlayerLayoutMode.sharedControls;
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
