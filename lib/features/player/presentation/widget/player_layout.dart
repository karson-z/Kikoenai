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

    // A. 起点 (Collapsed)：位于 Minibar 内部 (Offset.zero 附近)
    final double smallSize = minHeight - 12.0;
    final collapsedRect = Rect.fromLTWH(
        16.0,
        (minHeight - smallSize) / 2, // 垂直居中于 Minibar
        smallSize,
        smallSize
    );

    // B. 终点 (Expanded)：根据宽屏/窄屏区分
    Rect expandedTargetRect;

    if (isWideScreen) {
      // 【宽屏模式】：封面图固定在左侧分栏的中间
      // 左侧宽度 = 总宽度的一半
      final double leftColumnWidth = size.width / 2;
      // 限制封面最大尺寸
      final double bigWidth = (leftColumnWidth * 0.6).clamp(250.0, 300.0);

      expandedTargetRect = Rect.fromLTWH(
        (leftColumnWidth - bigWidth) / 2, // 左分栏水平居中
        padding.top + 100.0,              // 顶部距离
        bigWidth,
        bigWidth,
      );
    } else {
      // 【窄屏模式】：原有逻辑，在“大封面”和“小歌词头图”之间切换
      final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);

      // 状态1：看封面时的位置
      final Rect albumModeRect = Rect.fromLTWH(
          (size.width - bigWidth) / 2,
          padding.top + 80.0,
          bigWidth,
          bigWidth
      );

      // 状态2：看歌词时的位置 (变成标题栏小图)
      const double lyricsHeaderSize = 50.0;
      final Rect lyricsModeRect = Rect.fromLTWH(
          24.0,
          padding.top + 70 + (60 - lyricsHeaderSize) / 2,
          lyricsHeaderSize,
          lyricsHeaderSize
      );

      // 根据 lyricsProgress 插值
      expandedTargetRect = Rect.lerp(albumModeRect, lyricsModeRect, lyricsProgress)!;
    }

    // C. 计算当前帧 Hero 位置 (受面板展开进度控制)
    final Rect currentCoverRect = Rect.lerp(collapsedRect, expandedTargetRect, expandProgress)!;

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
    // --- 视频容器布局逻辑 (核心修改) ---
    if (hasChild(PlayerLayoutId.videoContainer) && isVideo) {
      // 视频在展开时，无论宽窄屏都强制占满全屏可用区域 无需减去系统状态栏高度，让黑色背景铺满。
      final Size videoSize = Size(size.width, size.height);
      layoutChild(PlayerLayoutId.videoContainer, BoxConstraints.tight(videoSize));
      // 视频随面板展开向上滑动进入
      positionChild(PlayerLayoutId.videoContainer, Offset(0,(1 - expandProgress) * size.height));
    }


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