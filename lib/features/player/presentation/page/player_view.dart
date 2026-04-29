import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 注意：请确保此处导入了你定义 panelControllerProvider 的文件
// import 'path_to_your_panel_controller_provider.dart';

import '../../../../core/widgets/layout/app_main_scaffold.dart';
import '../../data/service/player_view_controller.dart';
import '../provider/player_controller_provider.dart';
import '../widget/audio/player_background.dart';
import '../widget/audio/player_content.dart';
import '../widget/audio/player_hero_cover.dart';
import '../widget/player_layout.dart';
import '../widget/lyrics/player_lyrics_content.dart';
import '../widget/audio/player_mini_bar.dart';
import '../widget/other/player_top_bar.dart';
import '../widget/video/player_video_content.dart';

class PlayerView extends ConsumerStatefulWidget {
  final ValueListenable<double>? dragProgressNotifier;
  final double minHeight;

  const PlayerView({
    super.key,
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

    final shouldRenderVideo =
    ref.watch(playerControllerProvider.select((s) => s.isCurrentVideoView));

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
            LayoutId(
              id: PlayerLayoutId.background,
              child: shouldRenderVideo
                  ? const SizedBox.shrink()
                  : RepaintBoundary(
                child: PlayerBackground(expandedOpacity: expandedOpacity),
              ),
            ),
            LayoutId(
              id: PlayerLayoutId.videoContainer,
              child: shouldRenderVideo
                  ? Opacity(
                opacity: expandVal.clamp(0.0, 1.0),
                child: IgnorePointer(
                  ignoring: expandVal < 0.5,
                  child: const RepaintBoundary(
                    child: PlayerVideoContent(),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            LayoutId(
              id: PlayerLayoutId.bodyAlbum,
              child: shouldRenderVideo
                  ? const SizedBox.shrink()
                  : Opacity(
                opacity: expandedOpacity * currentAlbumAlpha,
                child: IgnorePointer(
                  ignoring: expandVal < 0.5 || (!isWide && lyricsVal > 0.5),
                  child: RepaintBoundary(
                    child: PlayerAlbumContent(track: currentTrack),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: PlayerLayoutId.bodyLyrics,
              child: shouldRenderVideo
                  ? const SizedBox.shrink()
                  : Opacity(
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
            LayoutId(
              id: PlayerLayoutId.minibar,
              child: Opacity(
                opacity: collapsedOpacity,
                child: IgnorePointer(
                  ignoring: collapsedOpacity < 0.05,
                  child: CollapsedMinibar(
                    track: currentTrack,
                    onTap: () => ref.read(panelControllerProvider).open(),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: PlayerLayoutId.topBar,
              child: shouldRenderVideo
                  ? const SizedBox.shrink()
                  : Opacity(
                opacity: expandedOpacity,
                child: IgnorePointer(
                  ignoring: expandedOpacity == 0,
                  child: RepaintBoundary(
                    child: TopBar(
                      onClose: () => ref.read(panelControllerProvider).close(),
                    ),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: PlayerLayoutId.coverHero,
              child: Opacity(
                opacity: shouldRenderVideo ? collapsedOpacity : 1.0,
                child: GestureDetector(
                  onTap: () {
                    if (expandVal < 0.5) {
                      ref.read(panelControllerProvider).open();
                    } else if (!isWide && !shouldRenderVideo) {
                      _controller.toggleLyrics();
                    }
                  },
                  child: FloatingCoverImage(
                    url: currentTrack?.extras?['mainCoverUrl'],
                    radiusValue:
                    isWide ? 8.0 : ui.lerpDouble(8.0, 4.0, lyricsVal)!,
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
