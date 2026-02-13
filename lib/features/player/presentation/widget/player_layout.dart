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
    // A. 计算 Minibar 中小图的位置 (起飞点)
    final double smallSize = minHeight - 20.0;

    final collapsedRect = Rect.fromLTWH(
        16.0,
        (minHeight - smallSize) / 2, // 垂直居中于 Minibar 高度内
        smallSize,
        smallSize
    );

    // B. 计算展开后的位置 (降落点)
    final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);
    final double bigTop = padding.top + 80.0;
    final double bigLeft = (size.width - bigWidth) / 2;
    final expandedAlbumRect = Rect.fromLTWH(bigLeft, bigTop, bigWidth, bigWidth);

    // C. 计算歌词模式小图位置
    const double lyricsHeaderSize = 50.0;
    final double lyricsHeaderTop = padding.top + 70 + (60 - lyricsHeaderSize) / 2;
    final expandedLyricsRect = Rect.fromLTWH(24.0, lyricsHeaderTop, lyricsHeaderSize, lyricsHeaderSize);
    // 插值计算 (计算当前帧的飞行位置)
    // 在“大图”和“歌词页小图”之间切换
    final Rect targetExpandedRect = Rect.lerp(expandedAlbumRect, expandedLyricsRect, lyricsProgress)!;
    final Rect currentCoverRect = Rect.lerp(collapsedRect, targetExpandedRect, expandProgress)!;

    final bodyConstraints = BoxConstraints.tight(size);

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

    if (hasChild(PlayerLayoutId.bodyAlbum)) {
      layoutChild(PlayerLayoutId.bodyAlbum, bodyConstraints);
      positionChild(PlayerLayoutId.bodyAlbum, Offset(0, (1 - expandProgress) * 100));
    }

    if (hasChild(PlayerLayoutId.bodyLyrics)) {
      layoutChild(PlayerLayoutId.bodyLyrics, bodyConstraints);
      positionChild(PlayerLayoutId.bodyLyrics, Offset(0, (1 - lyricsProgress) * 50));
    }

    // D. 布局 TopBar
    if (hasChild(PlayerLayoutId.topBar)) {
      layoutChild(PlayerLayoutId.topBar, BoxConstraints.tightFor(width: size.width, height: 60));
      positionChild(PlayerLayoutId.topBar, Offset(0, padding.top + 10));
    }

    // E. 布局 Cover Hero
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