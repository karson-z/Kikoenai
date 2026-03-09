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
  final bool isVideo; // 【新增】判断是否为视频模式

  PlayerLayoutDelegate({
    required this.expandProgress,
    required this.lyricsProgress,
    required this.minHeight,
    required this.padding,
    required this.isWideScreen,
    this.isVideo = false, // 默认音频
  });

  @override
  void performLayout(Size size) {
    // [Background] 背景铺满
    if (hasChild(PlayerLayoutId.background)) {
      layoutChild(PlayerLayoutId.background, BoxConstraints.tight(size));
      positionChild(PlayerLayoutId.background, Offset.zero);
    }

    // [Minibar] 始终位于顶部 (0,0)
    if (hasChild(PlayerLayoutId.minibar)) {
      layoutChild(PlayerLayoutId.minibar, BoxConstraints.tightFor(width: size.width, height: minHeight));
      positionChild(PlayerLayoutId.minibar, Offset.zero);
    }

    final double bodyTop = padding.top + 60; // 扣除状态栏和 TopBar 预留位

    // --- 视频容器布局逻辑 (核心修改) ---
    if (hasChild(PlayerLayoutId.videoContainer)) {
      // 视频在展开时，无论宽窄屏都强制占满全屏可用区域（减去顶部 Padding 防止遮挡系统状态栏）
      final Size videoSize = Size(size.width, size.height - padding.top);
      layoutChild(PlayerLayoutId.videoContainer, BoxConstraints.tight(videoSize));
      // 视频随面板展开向上滑动进入
      positionChild(PlayerLayoutId.videoContainer, Offset(0, padding.top + (1 - expandProgress) * size.height));
    }

    // --- 音频主体区域计算 ---
    final Size bodySize = Size(
        isWideScreen ? size.width / 2 : size.width,
        size.height - bodyTop
    );

    // [Body Album] 专辑/控制区域
    if (hasChild(PlayerLayoutId.bodyAlbum)) {
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

    // [Body Lyrics] 歌词区域
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

    // [TopBar] 下拉箭头和菜单
    if (hasChild(PlayerLayoutId.topBar)) {
      layoutChild(PlayerLayoutId.topBar, BoxConstraints.tightFor(width: size.width, height: 60));
      positionChild(PlayerLayoutId.topBar, Offset(0, padding.top + 10));
    }

    // --- Cover Hero 封面图动画逻辑 ---
    if (hasChild(PlayerLayoutId.coverHero)) {
      final double smallSize = minHeight - 12.0;
      final collapsedRect = Rect.fromLTWH(16.0, (minHeight - smallSize) / 2, smallSize, smallSize);

      Rect expandedTargetRect;
      if (isVideo) {
        // 如果是视频模式，封面在展开时收缩并隐藏在画面中心，避免干扰视频观看
        expandedTargetRect = Rect.fromLTWH(size.width / 2, bodyTop + 40, 0, 0);
      } else {
        // 音频原有逻辑
        expandedTargetRect = isWideScreen
            ? Rect.fromLTWH((bodySize.width - 300) / 2, bodyTop + 40, 300, 300)
            : Rect.fromLTWH((size.width - 300) / 2, bodyTop + 20, 300, 300);
      }

      final Rect currentCoverRect = Rect.lerp(collapsedRect, expandedTargetRect, expandProgress)!;
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