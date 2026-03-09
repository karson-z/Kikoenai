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
import '../widget/player_video_content.dart';

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
    final isWide = mediaQuery.size.width > 800;

    final currentTrack =
    ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    // 【新增】判断是否为视频
    final isVideo = currentTrack?.extras?['isVideo'] == true;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final expandVal = _controller.expandValue;
        final lyricsVal = _controller.lyricsValue;

        final collapsedOpacity = (1.0 - expandVal * 5).clamp(0.0, 1.0);
        final expandedOpacity = ((expandVal - 0.7) / 0.3).clamp(0.0, 1.0);

        double currentAlbumAlpha = isWide ? 1.0 : (1 - lyricsVal).clamp(0.0, 1.0);
        double currentLyricsAlpha = isWide ? 1.0 : lyricsVal.clamp(0.0, 1.0);

        return CustomMultiChildLayout(
          delegate: PlayerLayoutDelegate(
            expandProgress: expandVal,
            lyricsProgress: lyricsVal,
            minHeight: widget.minHeight,
            padding: padding,
            isWideScreen: isWide,
            isVideo: isVideo, // 【传入参数】
          ),
          children: [
            // 1. 背景层
            LayoutId(
              id: PlayerLayoutId.background,
              child: PlayerBackground(expandedOpacity: expandedOpacity),
            ),

            // 2. 视频内容层 (仅视频存在)
            if (isVideo)
              LayoutId(
                id: PlayerLayoutId.videoContainer,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5,
                    child: const PlayerVideoContent(), // 渲染自带控制器的 media_kit_video
                  ),
                ),
              ),

            // 3. 专辑内容层 (仅音频存在)
            if (!isVideo)
              LayoutId(
                id: PlayerLayoutId.bodyAlbum,
                child: Opacity(
                  opacity: expandedOpacity * currentAlbumAlpha,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5 || (!isWide && lyricsVal > 0.5),
                    child: PlayerAlbumContent(track: currentTrack),
                  ),
                ),
              ),

            // 4. 歌词内容层 (仅音频存在)
            if (!isVideo)
              LayoutId(
                id: PlayerLayoutId.bodyLyrics,
                child: Opacity(
                  opacity: expandedOpacity * currentLyricsAlpha,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5 || (!isWide && lyricsVal <= 0.5),
                    child: MobileLyricsContent(
                      isWideScreen: isWide,
                      track: currentTrack,
                      onTapHeader: isWide ? null : _controller.toggleLyrics,
                      padding: padding,
                    ),
                  ),
                ),
              ),

            // 5. 底部 Minibar (全局保留)
            LayoutId(
              id: PlayerLayoutId.minibar,
              child: Opacity(
                opacity: collapsedOpacity,
                child: IgnorePointer(
                  ignoring: collapsedOpacity < 0.05,
                  child: CollapsedMinibar(
                    track: currentTrack,
                    onTap: () => widget.panelController?.open(),
                  ),
                ),
              ),
            ),

            // 6. 顶部 TopBar (全局保留下拉收起按钮与扩展菜单)
            LayoutId(
              id: PlayerLayoutId.topBar,
              child: Opacity(
                opacity: expandedOpacity,
                child: IgnorePointer(
                  ignoring: expandedOpacity == 0,
                  child: TopBar(onClose: () => widget.panelController?.close()),
                ),
              ),
            ),

            // 7. 浮动封面
            LayoutId(
              id: PlayerLayoutId.coverHero,
              // 【核心】视频模式下，随着展开渐隐封面，仅作为 Minibar 中的小图可见
              child: Opacity(
                opacity: isVideo ? collapsedOpacity : 1.0,
                child: GestureDetector(
                  onTap: () {
                    if (expandVal < 0.5) {
                      widget.panelController?.open();
                    } else if (!isWide && !isVideo) {
                      _controller.toggleLyrics();
                    }
                  },
                  child: FloatingCoverImage(
                    url: currentTrack?.extras?['mainCoverUrl'],
                    radiusValue: isWide ? 8.0 : ui.lerpDouble(8.0, 4.0, lyricsVal)!,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}