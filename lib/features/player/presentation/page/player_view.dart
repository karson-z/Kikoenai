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

class PlayerView extends ConsumerStatefulWidget {
  final PanelController? panelController;
  final ValueListenable<double>? dragProgressNotifier;
  final double minHeight;

  const PlayerView({
    super.key,
    this.panelController,
    this.dragProgressNotifier,
    this.minHeight = 80.0,
  });

  @override
  ConsumerState<PlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends ConsumerState<PlayerView>
    with SingleTickerProviderStateMixin {
  late final PlayerViewController _controller;

  @override
  void initState() {
    super.initState();
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

    final isVideoTrack = currentTrack?.extras?['isVideo'] == true;
    final isAudioOnlyMode = ref.watch(audioOnlyModeProvider);
    final shouldRenderVideo = isVideoTrack && !isAudioOnlyMode;

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
            isVideo: shouldRenderVideo,
          ),
          children: [
            // 1. 背景层
            if (!shouldRenderVideo)
            LayoutId(
              id: PlayerLayoutId.background,
              // 【核心优化】：背景（尤其是包含高斯模糊时）是非常昂贵的，将其作为独立图层缓存。
              child: RepaintBoundary(
                child: PlayerBackground(expandedOpacity: expandedOpacity),
              ),
            ),

            // 2. 视频内容层
            if (shouldRenderVideo)
              LayoutId(
                id: PlayerLayoutId.videoContainer,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5,
                    // 【核心优化】：视频播放器组件属于重载组件，将其绘制与外层动画剥离。
                    child: const RepaintBoundary(
                      child: PlayerVideoContent(),
                    ),
                  ),
                ),
              ),

            // 3. 专辑内容层
            if (!shouldRenderVideo)
              LayoutId(
                id: PlayerLayoutId.bodyAlbum,
                child: Opacity(
                  opacity: expandedOpacity * currentAlbumAlpha,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5 || (!isWide && lyricsVal > 0.5),
                    child: RepaintBoundary(
                      child: PlayerAlbumContent(track: currentTrack),
                    ),
                  ),
                ),
              ),

            // 4. 歌词内容层
            if (!shouldRenderVideo)
              LayoutId(
                id: PlayerLayoutId.bodyLyrics,
                child: Opacity(
                  opacity: expandedOpacity * currentLyricsAlpha,
                  child: IgnorePointer(
                    ignoring: expandVal < 0.5 || (!isWide && lyricsVal <= 0.5),
                    child: RepaintBoundary(
                      child: MobileLyricsContent(
                        isWideScreen: isWide,
                        track: currentTrack,
                        onTapHeader: isWide ? null : _controller.toggleLyrics,
                        padding: padding,
                      ),
                    ),
                  ),
                ),
              ),

            // 5. 底部 Minibar
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

            // 6. 顶部 TopBar
            LayoutId(
              id: PlayerLayoutId.topBar,
              child: Opacity(
                opacity: expandedOpacity,
                child: IgnorePointer(
                  ignoring: expandedOpacity == 0,
                  // 顶部工具栏通常不会频繁重绘内部元素，加入隔离。
                  child: RepaintBoundary(
                    child: TopBar(onClose: () => widget.panelController?.close()),
                  ),
                ),
              ),
            ),

            // 7. 浮动封面 (故意不使用 RepaintBoundary)
            LayoutId(
              id: PlayerLayoutId.coverHero,
              child: Opacity(
                opacity: shouldRenderVideo ? collapsedOpacity : 1.0,
                child: GestureDetector(
                  onTap: () {
                    if (expandVal < 0.5) {
                      widget.panelController?.open();
                    } else if (!isWide && !shouldRenderVideo) {
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