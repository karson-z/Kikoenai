import 'package:flutter/material.dart';

// 定义布局中各个组件的 ID
enum PlayerLayoutId {
  background, // 背景渐变
  minibar,    // 底部小条
  coverHero,  // 浮动的封面图 (Hero)
  bodyAlbum,  // 展开后的专辑内容区
  bodyLyrics, // 展开后的歌词内容区
  topBar,     // 顶部下拉箭头
}

class PlayerLayoutDelegate extends MultiChildLayoutDelegate {
  final double expandProgress; // 0~1
  final double lyricsProgress; // 0~1
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
    // -------------------------------------------------------------
    // 1. 预计算阶段 (对应 LyricLayout.compute)
    // -------------------------------------------------------------

    // Minibar 布局区域
    final double smallSize = minHeight - 20.0;
    final collapsedRect = Rect.fromLTWH(
        16.0,
        size.height - minHeight + (minHeight - smallSize) / 2, // 注意：CustomMultiChildLayout 的原点在左上角
        smallSize,
        smallSize
    );

    // 展开态 - 封面位置
    final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);
    final double bigTop = padding.top + 80.0;
    final double bigLeft = (size.width - bigWidth) / 2;
    final expandedAlbumRect = Rect.fromLTWH(bigLeft, bigTop, bigWidth, bigWidth);

    // 展开态 - 歌词页头部小图位置
    const double lyricsHeaderSize = 50.0;
    final double lyricsHeaderTop = padding.top + 70 + (60 - lyricsHeaderSize) / 2;
    final expandedLyricsRect = Rect.fromLTWH(24.0, lyricsHeaderTop, lyricsHeaderSize, lyricsHeaderSize);

    // -------------------------------------------------------------
    // 2. 插值计算 (对应 LyricPainter 中的动画处理)
    // -------------------------------------------------------------

    // 目标展开位置：根据歌词进度，在“大封面”和“小标题图”之间插值
    final Rect targetExpandedRect = Rect.lerp(expandedAlbumRect, expandedLyricsRect, lyricsProgress)!;

    // 当前封面位置：根据展开进度，在“Minibar”和“目标展开位置”之间插值
    final Rect currentCoverRect = Rect.lerp(collapsedRect, targetExpandedRect, expandProgress)!;

    // -------------------------------------------------------------
    // 3. 布局每个子组件 (Layout & Position)
    // -------------------------------------------------------------

    // A. 布局背景 (铺满)
    if (hasChild(PlayerLayoutId.background)) {
      layoutChild(PlayerLayoutId.background, BoxConstraints.tight(size));
      positionChild(PlayerLayoutId.background, Offset.zero);
    }

    // B. 布局 Minibar (固定在底部，淡入淡出)
    if (hasChild(PlayerLayoutId.minibar)) {
      layoutChild(PlayerLayoutId.minibar, BoxConstraints.tightFor(width: size.width, height: minHeight));
      positionChild(PlayerLayoutId.minibar, Offset.zero);
    }

    // C. 布局主体内容 (Album Body & Lyrics Body)
    // 它们始终占据全屏，通过 Opacity 控制显隐
    final bodyConstraints = BoxConstraints.tight(size);

    if (hasChild(PlayerLayoutId.bodyAlbum)) {
      layoutChild(PlayerLayoutId.bodyAlbum, bodyConstraints);
      // 可以在这里做视差滚动效果
      positionChild(PlayerLayoutId.bodyAlbum, Offset(0, (1 - expandProgress) * 200));
    }

    if (hasChild(PlayerLayoutId.bodyLyrics)) {
      layoutChild(PlayerLayoutId.bodyLyrics, bodyConstraints);
      // 歌词页可以从下方滑入
      positionChild(PlayerLayoutId.bodyLyrics, Offset(0, (1 - lyricsProgress) * 50));
    }

    // D. 布局 TopBar (下拉箭头)
    if (hasChild(PlayerLayoutId.topBar)) {
      layoutChild(PlayerLayoutId.topBar, BoxConstraints.tightFor(width: size.width, height: 60));
      positionChild(PlayerLayoutId.topBar, Offset(0, padding.top + 10));
    }

    // E. 布局 Cover Hero (最上层，负责飞行动画)
    if (hasChild(PlayerLayoutId.coverHero)) {
      layoutChild(PlayerLayoutId.coverHero, BoxConstraints.tight(currentCoverRect.size));
      positionChild(PlayerLayoutId.coverHero, currentCoverRect.topLeft);
    }
  }

  @override
  bool shouldRelayout(PlayerLayoutDelegate oldDelegate) {
    return expandProgress != oldDelegate.expandProgress ||
        lyricsProgress != oldDelegate.lyricsProgress ||
        isWideScreen != oldDelegate.isWideScreen;
  }
}