import 'dart:ui' as ui;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/player_lyrics.dart';
import 'package:kikoenai/core/widgets/player/player_mode_button.dart';
import 'package:kikoenai/core/widgets/player/player_progress_bar.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:kikoenai/core/widgets/slider/sllding_up_panel_modify.dart';

import '../../constants/app_images.dart';
import '../../utils/data/colors_util.dart';
import '../image_box/simple_extended_image.dart';
import '../layout/provider/main_scaffold_provider.dart';

class MusicPlayerView extends ConsumerStatefulWidget {
  final PanelController? panelController;
  final VoidCallback? onQueuePressed;
  final ValueListenable<double>? dragProgressNotifier;
  final double minHeight;

  const MusicPlayerView({
    super.key,
    this.panelController,
    this.onQueuePressed,
    this.dragProgressNotifier,
    this.minHeight = 80.0,
  });

  @override
  ConsumerState<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends ConsumerState<MusicPlayerView> {
  bool _showLyrics = false;

  void _toggleLyrics() {
    setState(() => _showLyrics = !_showLyrics);
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    // 监听封面变化更新背景色
    ref.listen<String?>(
      playerControllerProvider
          .select((s) => s.currentTrack?.extras?['mainCoverUrl'] as String?),
      (prev, next) {
        if (next != null && next != prev) {
          ref.read(mainScaffoldProvider.notifier).fetchAlbumColors(next);
        }
      },
    );

    final bg = ref.watch(mainScaffoldProvider);
    final gradient = ColorUtils.buildGradient(
      start: bg.dominantColor,
      end: bg.vibrantColor.withOpacity(0.6),
      begin: Alignment.topCenter,
      endAlign: Alignment.bottomCenter,
    );
    final themeBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    // 1. 准备动画控制器 (默认为展开状态)
    final animation = widget.dragProgressNotifier ?? ValueNotifier(1.0);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          final padding = MediaQuery.of(context).padding;

          // 2. 计算关键帧位置 (Rect Calculation)
          final rects =
              _calculateRects(constraints.biggest, padding, isWideScreen);

          // 3. 使用 AnimatedBuilder 驱动动画
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final progress = animation.value;
              final double colorProgress =
                  ((progress - 0.15) / 0.85).clamp(0.0, 1.0);

              // B. 颜色插值 (Color Interpolation)
              // 这里的 ColorUtils.buildGradient 逻辑被拆解了，以便进行动态 lerp
              final Color startColor = Color.lerp(
                  themeBackgroundColor, bg.dominantColor, colorProgress)!;

              final Color endColor = Color.lerp(themeBackgroundColor,
                  bg.vibrantColor.withOpacity(0.6), colorProgress)!;
              final currentRect =
              Rect.lerp(rects.collapsed, rects.expanded, progress)!;

              final double collapsedRadius = rects.collapsed.width / 6.0;
              // 展开时期望的圆角半径 (圆角正方形)
              const double expandedRadius = 8.0;

              // 在圆形半径和圆角正方形半径之间插值
              final currentRadius = ui.lerpDouble(collapsedRadius, expandedRadius, progress)!;
              final collapsedOpacity = (1.0 - progress * 5).clamp(0.0, 1.0);
              // 展开内容透明度：后30%进度才开始显示，避免重叠干扰
              final expandedOpacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
              final viewParams = _PlayerViewParams(
                track: currentTrack,
                progress: progress,
                currentRect: currentRect,
                currentRadius: currentRadius,
                collapsedOpacity: collapsedOpacity,
                expandedOpacity: expandedOpacity,
                coverUrl:
                    currentTrack?.extras?['mainCoverUrl'] ?? placeholderImage,
                topPadding: padding.top,
              );
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // 随着拖拽，从纯色平滑过渡到原本的渐变色
                    colors: [startColor, endColor],
                  ),
                ),
                child: Stack(
                  children: [
                    // Layer 1: 展开后的主要内容 (Body)
                    Positioned.fill(
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Visibility(
                          visible: progress > 0.01,
                          child: isWideScreen
                              ? _buildDesktopBody(viewParams, rects.expanded)
                              : _buildMobileBody(viewParams, rects.expanded),
                        ),
                      ),
                    ),

                    // Layer 2: 收起时的 Minibar (Header)
                    _buildCollapsedMinibar(viewParams, rects.collapsed.width),

                    // Layer 3: 浮动图片 (Hero Image)
                    if (!_showLyrics || isWideScreen)
                      _buildFloatingHeroImage(viewParams),

                    // Layer 4: 顶部把手 (Top Indicator)
                    Positioned(
                      top: padding.top + 10,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: progress, // 随进度线性渐变
                        child: _topBar(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 封装 Rect 计算结果
  ({Rect collapsed, Rect expanded}) _calculateRects(
      Size size, EdgeInsets padding, bool isWideScreen) {
    // A. Collapsed Rect
    final double smallSize = widget.minHeight - 20.0;
    final collapsed = Rect.fromLTWH(
      16.0,
      (widget.minHeight - smallSize) / 2,
      smallSize,
      smallSize,
    );

    late Rect expanded;
    if (isWideScreen) {
      const double desktopImageSize = 350.0;
      final double leftPaneWidth = size.width / 2;
      final double targetLeft = (leftPaneWidth - desktopImageSize) / 2;
      double targetTop = (size.height - desktopImageSize) / 2 - 160.0;
      expanded = Rect.fromLTWH(
          targetLeft, targetTop, desktopImageSize, desktopImageSize);
    } else {
      final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);
      final double bigTop = padding.top + 60.0;
      final double bigLeft = (size.width - bigWidth) / 2;
      expanded = Rect.fromLTWH(bigLeft, bigTop, bigWidth, bigWidth);
    }

    return (collapsed: collapsed, expanded: expanded);
  }

  Widget _buildMobileBody(_PlayerViewParams params, Rect expandedRect) {
    if (_showLyrics) {
      return _buildMobileLyricsLayout(params);
    }
    return _buildMobileExpandedContent(context, params.track, expandedRect);
  }

  Widget _buildDesktopBody(_PlayerViewParams params, Rect expandedRect) {
    return _buildDesktopExpandedContent(context, params.track, expandedRect);
  }

  // --- Layer 2: Minibar ---
  Widget _buildCollapsedMinibar(_PlayerViewParams params, double smallSize) {
    // 1. 判断是否需要响应点击
    final bool isInteractive = params.collapsedOpacity > 0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: widget.minHeight,
      // 使用 IgnorePointer 保持原有逻辑
      child: IgnorePointer(
        ignoring: !isInteractive,
        child: Opacity(
          opacity: params.collapsedOpacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // 确保空白区域也能响应点击
            onTap: () {
              // 点击 MiniBar 时展开面板
              widget.panelController?.open();
            },

            child: Row(
              children: [
                if (_showLyrics && MediaQuery.of(context).size.width <= 800)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SimpleExtendedImage(
                          params.coverUrl,
                          width: smallSize, height: smallSize, fit: BoxFit.cover),
                    ),
                  )
                else
                  SizedBox(width: 16.0 + smallSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(params.track?.title ?? "未播放",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(params.track?.artist ?? "未知艺人",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // 控制按钮区域不需要处理，它们有自己的 IconButton 点击事件
                _buildMiniControlButtons(ref),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Layer 3: Floating Image ---
  Widget _buildFloatingHeroImage(_PlayerViewParams params) {
    return Positioned.fromRect(
      rect: params.currentRect,
      child: GestureDetector(
        onTap: params.progress > 0.5 ? _toggleLyrics : null,
        child: Container(
          decoration: BoxDecoration(
            // 外层容器圆角
            borderRadius: BorderRadius.circular(params.currentRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2 * params.progress),
                offset: const Offset(0, 10),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          // 使用 ClipRRect 裁剪图片
          child: SimpleExtendedImage(
            borderRadius: BorderRadius.circular(params.currentRadius),
            params.coverUrl,
            width: params.currentRect.width,
            height: params.currentRect.height,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileExpandedContent(
      BuildContext context, MediaItem? track, Rect imageRect) {

    final double minAvailableHeight = MediaQuery.of(context).size.height - (imageRect.bottom + 30 + 40);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: imageRect.bottom + 30, bottom: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minAvailableHeight > 0 ? minAvailableHeight : 0,
        ),
        child: Column(
          // 当高度被撑开超过一屏时，spaceEvenly 实际上会表现为 start，这是符合预期的
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _info(track),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: PlayerProgressBar(),
                ),
                const SizedBox(height: 20),
                _controls(ref),
              ],
            ),
            _volume(ref),
          ],
        ),
      ),
    );
  }

  // --- 桌面端展开内容 ---
  Widget _buildDesktopExpandedContent(
      BuildContext context, MediaItem? track, Rect imageRect) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: imageRect.bottom + 40),
                  child: Column(
                    children: [
                      _info(track),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48.0),
                        child: PlayerProgressBar(),
                      ),
                      const SizedBox(height: 30),
                      _controls(ref),
                      const SizedBox(height: 20),
                      SizedBox(width: 300, child: _volume(ref)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 32, top: 62, bottom: 32),
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 40),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const LyricsView(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 歌词页布局  ---
  Widget _buildMobileLyricsLayout(_PlayerViewParams params) {
    return Column(
      children: [
        SizedBox(height: params.topPadding + 40),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SimpleExtendedImage(params.coverUrl,
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(params.track?.title ?? "未播放",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text(params.track?.artist ?? "未知艺人",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              _buildMiniPlayButton(ref),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                color: Colors.white,
                onPressed: _toggleLyrics,
              ),
            ],
          ),
        ),
        Expanded(
            child: LyricsView(
                key: const ValueKey('lyrics'), onTap: _toggleLyrics)),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      width: double.infinity,
      height: 40,
      alignment: Alignment.center,
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  Widget _info(MediaItem? track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(track?.title ?? "没有播放的曲目",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(track?.artist ?? "未知艺人",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _controls(WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final playing =
        ref.watch(playerControllerProvider.select((s) => s.playing));
    final isFirst =
        ref.watch(playerControllerProvider.select((s) => s.isFirst));
    final isLast = ref.watch(playerControllerProvider.select((s) => s.isLast));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayModeButton(),
            const SizedBox(width: 24),
            IconButton(
                onPressed: isFirst ? null : controller.previous,
                icon: const Icon(Icons.skip_previous_rounded,
                    color: Colors.white, size: 36)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => playing ? controller.pause() : controller.play(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 54,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
                onPressed: isLast ? null : controller.next,
                icon: const Icon(Icons.skip_next_rounded,
                    color: Colors.white, size: 36)),
            const SizedBox(width: 24),
            IconButton(
                onPressed: widget.onQueuePressed,
                icon: const Icon(Icons.queue_music_sharp, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _volume(WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final volume = ref.watch(playerControllerProvider.select((s) => s.volume));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
            child: Slider(
                value: volume,
                min: 0,
                max: 1,
                onChanged: controller.setVolume,
                activeColor: Colors.white,
                inactiveColor: Colors.white30),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniControlButtons(WidgetRef ref) {
    final playing =
        ref.watch(playerControllerProvider.select((s) => s.playing));
    final controller = ref.read(playerControllerProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: controller.previous),
        IconButton(
            icon:
                Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            onPressed: () => playing ? controller.pause() : controller.play()),
        IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: controller.next),
      ],
    );
  }

  Widget _buildMiniPlayButton(WidgetRef ref) {
    final playing =
        ref.watch(playerControllerProvider.select((s) => s.playing));
    final controller = ref.read(playerControllerProvider.notifier);
    return IconButton(
        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
        iconSize: 32,
        color: Colors.white,
        onPressed: () => playing ? controller.pause() : controller.play());
  }
}

/// 辅助数据类：用于在 Widget 方法间传递统一的动画参数
class _PlayerViewParams {
  final MediaItem? track;
  final double progress;
  final Rect currentRect;
  final double currentRadius;
  final double collapsedOpacity;
  final double expandedOpacity;
  final String coverUrl;
  final double topPadding;

  _PlayerViewParams({
    required this.track,
    required this.progress,
    required this.currentRect,
    required this.currentRadius,
    required this.collapsedOpacity,
    required this.expandedOpacity,
    required this.coverUrl,
    required this.topPadding,
  });
}
