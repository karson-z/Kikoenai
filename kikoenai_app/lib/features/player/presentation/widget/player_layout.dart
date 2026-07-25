import 'package:flutter/material.dart';

enum PlayerLayoutId {
  background,
  videoContainer,
  minibar,
  coverHero,
  bodyLyrics,
  topBar,
  playerInfo,
  progressBar,
  playerControls,
  volumeSlider,
}

class PlayerLayoutDelegate extends MultiChildLayoutDelegate {
  final double expandProgress;
  final double lyricsProgress;
  final double minHeight;
  final EdgeInsets padding;
  final bool isWideScreen;

  PlayerLayoutDelegate({
    required this.expandProgress,
    required this.lyricsProgress,
    required this.minHeight,
    required this.padding,
    required this.isWideScreen,
  });

  @override
  void performLayout(Size size) {
    final double smallSize = minHeight - 10;
    final collapsedRect = Rect.fromLTWH(
        12.0,
        (minHeight - smallSize) / 2,
        smallSize,
        smallSize
    );

    Rect expandedTargetRect;
    double controlsBaseY = 0.0;

    if (isWideScreen) {
      final double leftColumnWidth = size.width / 2;
      final double bigWidth = (leftColumnWidth * 0.6).clamp(250.0, 350.0);
      expandedTargetRect = Rect.fromLTWH(
        (leftColumnWidth - bigWidth) / 2,
        padding.top + 100.0,
        bigWidth,
        bigWidth,
      );
      controlsBaseY = expandedTargetRect.bottom;
    } else {
      final double bigWidth = (size.width * 0.75).clamp(300.0, 450.0);
      final Rect albumModeRect = Rect.fromLTWH(
          (size.width - bigWidth) / 2,
          padding.top + 80.0,
          bigWidth,
          bigWidth
      );
      controlsBaseY = albumModeRect.bottom;

      const double lyricsHeaderSize = 50.0;
      final Rect lyricsModeRect = Rect.fromLTWH(
          24.0,
          padding.top + 70 + (60 - lyricsHeaderSize) / 2,
          lyricsHeaderSize,
          lyricsHeaderSize
      );
      expandedTargetRect = Rect.lerp(albumModeRect, lyricsModeRect, lyricsProgress)!;
    }

    final Rect currentCoverRect = Rect.lerp(collapsedRect, expandedTargetRect, expandProgress)!;

    if (hasChild(PlayerLayoutId.background)) {
      layoutChild(PlayerLayoutId.background, BoxConstraints.tight(size));
      positionChild(PlayerLayoutId.background, Offset.zero);
    }

    if (hasChild(PlayerLayoutId.videoContainer)) {
      layoutChild(PlayerLayoutId.videoContainer, BoxConstraints.tight(size));
      positionChild(PlayerLayoutId.videoContainer, Offset.zero);
    }

    if (hasChild(PlayerLayoutId.minibar)) {
      layoutChild(PlayerLayoutId.minibar, BoxConstraints.tightFor(width: size.width, height: minHeight));
      positionChild(PlayerLayoutId.minibar, Offset.zero);
    }

    _layoutIndependentControls(size, controlsBaseY);

    if (hasChild(PlayerLayoutId.bodyLyrics)) {
      if (isWideScreen) {
        layoutChild(PlayerLayoutId.bodyLyrics, BoxConstraints(
          minWidth: size.width / 2, maxWidth: size.width / 2,
          minHeight: size.height, maxHeight: size.height,
        ));
        positionChild(PlayerLayoutId.bodyLyrics, Offset(size.width / 2, (1 - expandProgress) * 100));
      } else {
        layoutChild(PlayerLayoutId.bodyLyrics, BoxConstraints.tight(size));
        positionChild(PlayerLayoutId.bodyLyrics, Offset(0, (1 - lyricsProgress) * 50));
      }
    }

    if (hasChild(PlayerLayoutId.topBar)) {
      layoutChild(PlayerLayoutId.topBar, BoxConstraints.tightFor(width: size.width, height: 60));
      positionChild(PlayerLayoutId.topBar, Offset(0, padding.top + 10));
    }

    if (hasChild(PlayerLayoutId.coverHero)) {
      layoutChild(PlayerLayoutId.coverHero, BoxConstraints.tight(currentCoverRect.size));
      positionChild(PlayerLayoutId.coverHero, currentCoverRect.topLeft);
    }
  }

  void _layoutIndependentControls(Size size, double baseY) {
    final double columnWidth = isWideScreen ? size.width / 2 : size.width;
    final BoxConstraints constraints = BoxConstraints(maxWidth: columnWidth);

    final Size infoSize = hasChild(PlayerLayoutId.playerInfo)
        ? layoutChild(PlayerLayoutId.playerInfo, constraints) : Size.zero;
    final Size progressSize = hasChild(PlayerLayoutId.progressBar)
        ? layoutChild(PlayerLayoutId.progressBar, constraints) : Size.zero;
    final Size controlsSize = hasChild(PlayerLayoutId.playerControls)
        ? layoutChild(PlayerLayoutId.playerControls, constraints) : Size.zero;
    final Size volumeSize = hasChild(PlayerLayoutId.volumeSlider)
        ? layoutChild(PlayerLayoutId.volumeSlider, constraints) : Size.zero;

    final double totalHeight = infoSize.height + progressSize.height + controlsSize.height + volumeSize.height;
    final double availableSpace = size.height - baseY;

    int activeCount = 0;
    if (infoSize != Size.zero) activeCount++;
    if (progressSize != Size.zero) activeCount++;
    if (controlsSize != Size.zero) activeCount++;
    if (volumeSize != Size.zero) activeCount++;

    final double gap = (activeCount > 0 && availableSpace > totalHeight)
        ? (availableSpace - totalHeight) / (activeCount + 1)
        : 0.0;

    double currentY = baseY + gap + ((1 - expandProgress) * 100);

    void positionComponent(PlayerLayoutId id, Size componentSize) {
      if (hasChild(id) && componentSize != Size.zero) {
        final double dx = (columnWidth - componentSize.width) / 2;
        positionChild(id, Offset(dx, currentY));
        currentY += componentSize.height + gap;
      }
    }

    positionComponent(PlayerLayoutId.playerInfo, infoSize);
    positionComponent(PlayerLayoutId.progressBar, progressSize);
    positionComponent(PlayerLayoutId.playerControls, controlsSize);
    positionComponent(PlayerLayoutId.volumeSlider, volumeSize);
  }

  @override
  bool shouldRelayout(PlayerLayoutDelegate oldDelegate) {
    return expandProgress != oldDelegate.expandProgress ||
        lyricsProgress != oldDelegate.lyricsProgress ||
        isWideScreen != oldDelegate.isWideScreen;
  }
}