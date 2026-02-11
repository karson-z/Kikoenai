// music_player_view_refactored.dart
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
    final padding = MediaQuery.of(context).padding;
    final currentTrack = ref.watch(playerControllerProvider.select((s) => s.currentTrack));
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final expandVal = _controller.expandValue;
        final lyricsVal = _controller.lyricsValue;
        // 计算透明度 (View Params)
        final collapsedOpacity = (1.0 - expandVal * 5).clamp(0.0, 1.0);
        final expandedOpacity = ((expandVal - 0.7) / 0.3).clamp(0.0, 1.0);
        final albumOpacity = (1 - lyricsVal).clamp(0.0, 1.0);
        final lyricsOpacity = lyricsVal.clamp(0.0, 1.0);

        return CustomMultiChildLayout(
          delegate: PlayerLayoutDelegate(
            expandProgress: expandVal,
            lyricsProgress: lyricsVal,
            minHeight: widget.minHeight,
            padding: padding,
            isWideScreen: MediaQuery.of(context).size.width > 800,
          ),
          children: [
            // 1. 背景层
            LayoutId(
              id: PlayerLayoutId.background,
              child: PlayerBackground(
                expandedOpacity: expandedOpacity,
              ),
            ),

            // 2. 专辑内容层 (Album Body)
            LayoutId(
              id: PlayerLayoutId.bodyAlbum,
              child: Opacity(
                opacity: expandedOpacity * albumOpacity,
                child: IgnorePointer(
                  ignoring: lyricsVal > 0.5 || expandVal < 0.5,
                  child: PlayerAlbumContent(track: currentTrack),
                ),
              ),
            ),

            // 3. 歌词内容层 (Lyrics Body)
            LayoutId(
              id: PlayerLayoutId.bodyLyrics,
              child: Opacity(
                opacity: expandedOpacity * lyricsOpacity,
                child: IgnorePointer(
                  ignoring: lyricsVal <= 0.5 || expandVal < 0.5,
                  child: MobileLyricsContent(
                    track: currentTrack,
                    onTapHeader: _controller.toggleLyrics,
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
                  ignoring: collapsedOpacity == 0,
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
                opacity: expandedOpacity, // 复用展开透明度
                child: TopBar(
                  onClose: () => widget.panelController?.close(),
                ),
              ),
            ),

            // 6. 浮动封面 (Hero Image) - 必须放在最后以覆盖其他层
            LayoutId(
              id: PlayerLayoutId.coverHero,
              child: GestureDetector(
                onTap: () {
                  if (expandVal > 0.5) {
                    _controller.toggleLyrics();
                  } else {
                    widget.panelController?.open();
                  }
                },
                child: FloatingCoverImage(
                  url: currentTrack?.extras?['mainCoverUrl'],
                  radiusValue: ui.lerpDouble(8.0, 4.0, lyricsVal)!, // 动态圆角
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}