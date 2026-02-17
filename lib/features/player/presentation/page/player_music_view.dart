import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/slider/sllding_up_panel_modify.dart';
import '../../data/service/player_view_controller.dart';
import '../provider/player_controller_provider.dart';
import '../widget/player_background.dart';
import '../widget/player_content.dart';
import '../widget/player_hero_cover.dart';
import '../widget/player_layout.dart';
import '../widget/player_lyrics_content.dart';
import '../widget/player_mini_bar.dart';
import '../widget/player_top_bar.dart';

class MusicPlayerView extends ConsumerStatefulWidget {
  final PanelController? panelController;
  final ValueListenable<double>? dragProgressNotifier;
  final double minHeight;

  const MusicPlayerView({
    super.key,
    this.panelController,
    this.dragProgressNotifier,
    this.minHeight = 80.0,
  });

  @override
  ConsumerState<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends ConsumerState<MusicPlayerView>
    with SingleTickerProviderStateMixin {
  late final PlayerViewController _controller;

  @override
  void initState() {
    super.initState();
    // 初始化逻辑控制器
    _controller = PlayerViewController(
      vsync: this,
      expandProgress: widget.dragProgressNotifier ?? ValueNotifier(0.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final isWide = mediaQuery.size.width > 800; // 【核心判断】是否为宽屏

    final currentTrack =
    ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final expandVal = _controller.expandValue; // 展开进度 0~1
        final lyricsVal = _controller.lyricsValue; // 歌词切换进度 0~1

        // 1. 计算基础透明度 (受展开进度控制)
        final collapsedOpacity = (1.0 - expandVal * 5).clamp(0.0, 1.0);
        final expandedOpacity = ((expandVal - 0.7) / 0.3).clamp(0.0, 1.0);

        // 2. 计算分栏透明度 (受宽屏/窄屏逻辑控制)
        double currentAlbumAlpha;
        double currentLyricsAlpha;

        if (isWide) {
          // 【宽屏模式】：两者共存，透明度只受 expandedOpacity 影响，不受 lyricsVal 影响
          currentAlbumAlpha = 1.0;
          currentLyricsAlpha = 1.0;
        } else {
          // 【窄屏模式】：互斥显示，受 lyricsVal 影响
          currentAlbumAlpha = (1 - lyricsVal).clamp(0.0, 1.0);
          currentLyricsAlpha = lyricsVal.clamp(0.0, 1.0);
        }

        return CustomMultiChildLayout(
          delegate: PlayerLayoutDelegate(
            expandProgress: expandVal,
            lyricsProgress: lyricsVal,
            minHeight: widget.minHeight,
            padding: padding,
            isWideScreen: isWide, // 传入宽屏标志
          ),
          children: [
            // 1. 背景层
            LayoutId(
              id: PlayerLayoutId.background,
              child: PlayerBackground(
                expandedOpacity: expandedOpacity,
              ),
            ),

            // 2. 专辑内容层 (Album Body) - 左侧或全屏
            LayoutId(
              id: PlayerLayoutId.bodyAlbum,
              child: Opacity(
                opacity: expandedOpacity * currentAlbumAlpha,
                child: IgnorePointer(
                  // 宽屏时：只要展开了(expandVal > 0.5) 就可以点击
                  // 窄屏时：必须是专辑模式(lyricsVal < 0.5) 且展开了 才可以点击
                  ignoring: expandVal < 0.5 || (!isWide && lyricsVal > 0.5),
                  child: PlayerAlbumContent(track: currentTrack),
                ),
              ),
            ),

            // 3. 歌词内容层 (Lyrics Body) - 右侧或全屏
            LayoutId(
              id: PlayerLayoutId.bodyLyrics,
              child: Opacity(
                opacity: expandedOpacity * currentLyricsAlpha,
                child: IgnorePointer(
                  // 宽屏时：只要展开了就可以点击
                  // 窄屏时：必须是歌词模式(lyricsVal > 0.5) 且展开了 才可以点击
                  ignoring: expandVal < 0.5 || (!isWide && lyricsVal <= 0.5),
                  child: MobileLyricsContent(
                    isWideScreen:isWide,
                    track: currentTrack,
                    // 宽屏下如果不需要点击标题切换，可以在这里传 null 或者内部做判断
                    onTapHeader: isWide ? null : _controller.toggleLyrics,
                    padding: padding,
                  ),
                ),
              ),
            ),

            // 4. 底部 Minibar
            LayoutId(
              id: PlayerLayoutId.minibar,
              child: Opacity(
                opacity: collapsedOpacity,
                child: IgnorePointer(
                  // 修复浮点数精度问题，防止微弱透明度下的误触
                  ignoring: collapsedOpacity < 0.05,
                  child: CollapsedMinibar(
                    track: currentTrack,
                    onTap: () => widget.panelController?.open(),
                  ),
                ),
              ),
            ),

            // 5. 顶部 TopBar
            LayoutId(
              id: PlayerLayoutId.topBar,
              child: Opacity(
                opacity: expandedOpacity,
                child: IgnorePointer(
                  ignoring: expandedOpacity == 0,
                  child: TopBar(
                    onClose: () => widget.panelController?.close(),
                  ),
                ),
              ),
            ),

            // 6. 浮动封面 (Hero Image)
            LayoutId(
              id: PlayerLayoutId.coverHero,
              child: GestureDetector(
                onTap: () {
                  if (expandVal < 0.5) {
                    // 收起状态：点击打开
                    widget.panelController?.open();
                  } else {
                    if (!isWide) {
                      _controller.toggleLyrics();
                    }
                  }
                },
                child: FloatingCoverImage(
                  url: currentTrack?.extras?['mainCoverUrl'],
                  // 宽屏时固定圆角，窄屏时随歌词进度变化
                  radiusValue: isWide
                      ? 8.0
                      : ui.lerpDouble(8.0, 4.0, lyricsVal)!,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}