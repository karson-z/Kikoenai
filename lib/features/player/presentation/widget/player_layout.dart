import 'package:flutter/material.dart';

enum PlayerLayoutId {
  background,
  videoContainer,
  minibar,
  coverHero,
  bodyAlbum,
  bodyLyrics,
  topBar,
}

class PlayerLayoutDelegate extends MultiChildLayoutDelegate {
  final double expandProgress;
  final double lyricsProgress;
  final double minHeight;
  final EdgeInsets padding;
  final bool isWideScreen;
  final bool isVideo;

  PlayerLayoutDelegate({
    required this.expandProgress,
    required this.lyricsProgress,
    required this.minHeight,
    required this.padding,
    required this.isWideScreen,
    this.isVideo = false,
  });

  @override
  void performLayout(Size size) {
    // A. 起点 (Collapsed)：位于 Minibar 内部 (Offset.zero 附近)
    final double smallSize = minHeight - 12.0;
    final collapsedRect = Rect.fromLTWH(
        16.0,
        (minHeight - smallSize) / 2,
        smallSize,
        smallSize
    );

    // B. 终点 (Expanded)：根据宽屏/窄屏区分
    Rect expandedTargetRect;

    if (isWideScreen) {
      final double leftColumnWidth = size.width / 2;
      final double bigWidth = (leftColumnWidth * 0.6).clamp(250.0, 300.0);
      expandedTargetRect = Rect.fromLTWH(
        (leftColumnWidth - bigWidth) / 2,
        padding.top + 100.0,
        bigWidth,
        bigWidth,
      );
    } else {
      final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);
      final Rect albumModeRect = Rect.fromLTWH(
          (size.width - bigWidth) / 2,
          padding.top + 80.0,
          bigWidth,
          bigWidth
      );
      const double lyricsHeaderSize = 50.0;
      final Rect lyricsModeRect = Rect.fromLTWH(
          24.0,
          padding.top + 70 + (60 - lyricsHeaderSize) / 2,
          lyricsHeaderSize,
          lyricsHeaderSize
      );
      expandedTargetRect = Rect.lerp(albumModeRect, lyricsModeRect, lyricsProgress)!;
    }

    // C. 计算当前帧 Hero 位置
    final Rect currentCoverRect = Rect.lerp(collapsedRect, expandedTargetRect, expandProgress)!;

    // [Background] 背景层
    if (hasChild(PlayerLayoutId.background)) {
      if (isVideo) {
        layoutChild(PlayerLayoutId.background, BoxConstraints.tight(Size.zero));
        positionChild(PlayerLayoutId.background, Offset.zero);
      } else {
        layoutChild(PlayerLayoutId.background, BoxConstraints.tight(size));
        positionChild(PlayerLayoutId.background, Offset.zero);
      }
    }

    // [Minibar] 始终位于顶部 (0,0)
    if (hasChild(PlayerLayoutId.minibar)) {
      layoutChild(PlayerLayoutId.minibar, BoxConstraints.tightFor(width: size.width, height: minHeight));
      positionChild(PlayerLayoutId.minibar, Offset.zero);
    }

    // [Video Container] 视频内容层
    if (hasChild(PlayerLayoutId.videoContainer)) {
      if (isVideo) {
        final Size videoSize = Size(size.width, size.height);
        layoutChild(PlayerLayoutId.videoContainer, BoxConstraints.tight(videoSize));
        positionChild(PlayerLayoutId.videoContainer, Offset(0,(1 - expandProgress) * size.height));
      } else {
        layoutChild(PlayerLayoutId.videoContainer, BoxConstraints.tight(Size.zero));
        positionChild(PlayerLayoutId.videoContainer, Offset.zero);
      }
    }

    // [Body Album] 专辑/控制区域
    if (hasChild(PlayerLayoutId.bodyAlbum)) {
      if (isVideo) {
        layoutChild(PlayerLayoutId.bodyAlbum, BoxConstraints.tight(Size.zero));
        positionChild(PlayerLayoutId.bodyAlbum, Offset.zero);
      } else {
        if (isWideScreen) {
          layoutChild(PlayerLayoutId.bodyAlbum, BoxConstraints(
            minWidth: size.width / 2, maxWidth: size.width / 2,
            minHeight: size.height, maxHeight: size.height,
          ));
          positionChild(PlayerLayoutId.bodyAlbum, Offset(0, (1 - expandProgress) * 100));
        } else {
          layoutChild(PlayerLayoutId.bodyAlbum, BoxConstraints.tight(size));
          positionChild(PlayerLayoutId.bodyAlbum, Offset(0, (1 - expandProgress) * 100));
        }
      }
    }

    // [Body Lyrics] 歌词区域
    if (hasChild(PlayerLayoutId.bodyLyrics)) {
      if (isVideo) {
        layoutChild(PlayerLayoutId.bodyLyrics, BoxConstraints.tight(Size.zero));
        positionChild(PlayerLayoutId.bodyLyrics, Offset.zero);
      } else {
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
    }

    // [TopBar] 下拉箭头和菜单
    if (hasChild(PlayerLayoutId.topBar)) {
      if (isVideo) {
        layoutChild(PlayerLayoutId.topBar, BoxConstraints.tight(Size.zero));
        positionChild(PlayerLayoutId.topBar, Offset.zero);
      } else {
        layoutChild(PlayerLayoutId.topBar, BoxConstraints.tightFor(width: size.width, height: 60));
        positionChild(PlayerLayoutId.topBar, Offset(0, padding.top + 10));
      }
    }

    // [Cover Hero] 封面浮动图
    if (hasChild(PlayerLayoutId.coverHero)) {
      layoutChild(PlayerLayoutId.coverHero, BoxConstraints.tight(currentCoverRect.size));
      positionChild(PlayerLayoutId.coverHero, currentCoverRect.topLeft);
    }
  }

  @override
  bool shouldRelayout(PlayerLayoutDelegate oldDelegate) {
    return expandProgress != oldDelegate.expandProgress ||
        lyricsProgress != oldDelegate.lyricsProgress ||
        isVideo != oldDelegate.isVideo ||
        isWideScreen != oldDelegate.isWideScreen;
  }
}