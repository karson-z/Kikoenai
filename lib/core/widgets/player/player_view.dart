import 'dart:ui' as ui;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/device_type.dart';
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

class _MusicPlayerViewState extends ConsumerState<MusicPlayerView>
    with SingleTickerProviderStateMixin { // 1. 混入 TickerProvider

  // 用于控制歌词页切换动画 (0.0 = 封面模式, 1.0 = 歌词模式)
  late final AnimationController _lyricsCtrl;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _lyricsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      animationBehavior: AnimationBehavior.normal
    );
  }

  @override
  void dispose() {
    _lyricsCtrl.dispose();
    super.dispose();
  }

  void _toggleLyrics() {
    setState(() => _showLyrics = !_showLyrics);
    if (_showLyrics) {
      _lyricsCtrl.forward();
    } else {
      _lyricsCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack =
    ref.watch(playerControllerProvider.select((s) => s.currentTrack));

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
    final animation = widget.dragProgressNotifier ?? ValueNotifier(1.0);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          final padding = MediaQuery.of(context).padding;

          // 使用 AnimatedBuilder 监听两个动画：拖拽进度 + 歌词切换进度
          return AnimatedBuilder(
            animation: Listenable.merge([animation, _lyricsCtrl]),
            builder: (context, child) {
              final progress = animation.value;
              // 歌词模式动画进度 (0~1)
              final lyricsValue = _lyricsCtrl.value;

              // 2. 计算所有关键 Rect
              final rects = _calculateRects(
                  constraints.biggest,
                  padding,
                  isWideScreen
              );

              // 3. 计算目标 "展开态" Rect
              // 如果 lyricsValue 为 0，目标是中间大图；为 1，目标是顶部小图
              final Rect targetExpandedRect = Rect.lerp(
                  rects.expandedAlbum,
                  rects.expandedLyrics,
                  lyricsValue
              )!;

              // 4. 计算最终当前 Rect (结合拖拽进度)
              // 无论目标是哪里，progress 为 0 时都会回到 collapsed (Minibar)
              final currentRect = Rect.lerp(
                  rects.collapsed,
                  targetExpandedRect,
                  progress
              )!;

              // 计算背景色插值
              final double colorProgress =
              ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
              final Color startColor = Color.lerp(
                  themeBackgroundColor, bg.dominantColor, colorProgress)!;
              final Color endColor = Color.lerp(themeBackgroundColor,
                  bg.vibrantColor.withOpacity(0.6), colorProgress)!;
              // 计算圆角插值
              final double collapsedRadius = rects.collapsed.width / 6.0;
              const double albumRadius = 8.0;
              const double lyricsRadius = 4.0;
              // 展开态的目标圆角
              final double targetExpandedRadius = ui.lerpDouble(albumRadius, lyricsRadius, lyricsValue)!;
              final currentRadius = ui.lerpDouble(collapsedRadius, targetExpandedRadius, progress)!;
              final collapsedOpacity = (1.0 - progress * 5).clamp(0.0, 1.0);
              final expandedOpacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

              final viewParams = _PlayerViewParams(
                track: currentTrack,
                progress: progress,
                lyricsValue: lyricsValue, // 传入歌词进度
                currentRect: currentRect,
                currentRadius: currentRadius,
                collapsedOpacity: collapsedOpacity,
                expandedOpacity: expandedOpacity,
                coverUrl: currentTrack?.extras?['mainCoverUrl'] ?? placeholderImage,
                topPadding: padding.top,
              );

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [startColor, endColor],
                  ),
                ),
                child: Stack(
                  children: [
                    // Layer 1: Body (歌词页或封面页)
                    Positioned.fill(
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Visibility(
                          visible: progress > 0.01,
                          child: isWideScreen
                              ? _buildDesktopBody(viewParams, targetExpandedRect)
                              : _buildMobileBody(viewParams, targetExpandedRect),
                        ),
                      ),
                    ),

                    // Layer 2: Minibar
                    _buildCollapsedMinibar(viewParams, rects.collapsed.width),

                    // Layer 3: Floating Hero Image (始终显示，负责所有过渡)
                    if (isWideScreen || progress > 0.01 || collapsedOpacity > 0)
                      _buildFloatingHeroImage(viewParams),

                    // Layer 4: Top Indicator
                    Positioned(
                      top: padding.top + 10,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: progress,
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

  /// 计算三种状态下的 Rect
  /// 返回: (collapsed, expandedAlbum, expandedLyrics)
  ({Rect collapsed, Rect expandedAlbum, Rect expandedLyrics}) _calculateRects(
      Size size, EdgeInsets padding, bool isWideScreen) {

    // 1. 收起状态 (MiniBar)
    final double smallSize = widget.minHeight - 20.0;
    final collapsed = Rect.fromLTWH(
      16.0,
      (widget.minHeight - smallSize) / 2,
      smallSize,
      smallSize,
    );

    // 2. 展开状态 - 封面模式 (中间大图)
    late Rect expandedAlbum;
    if (isWideScreen) {
      const double desktopImageSize = 350.0;
      final double leftPaneWidth = size.width / 2;
      final double targetLeft = (leftPaneWidth - desktopImageSize) / 2;
      double targetTop = (size.height - desktopImageSize) / 2 - 160.0;
      expandedAlbum = Rect.fromLTWH(
          targetLeft, targetTop, desktopImageSize, desktopImageSize);
    } else {
      final double bigWidth = (size.width * 0.75).clamp(250.0, 350.0);
      final double bigTop = padding.top + 60.0;
      final double bigLeft = (size.width - bigWidth) / 2;
      expandedAlbum = Rect.fromLTWH(bigLeft, bigTop, bigWidth, bigWidth);
    }

    // 3. 展开状态 - 歌词模式 (顶部 Header 小图)
    // 位置需要和 _buildMobileLyricsLayout 中的 Row > Placeholder 对应
    const double lyricsHeaderImageSize = 50.0;
    final double lyricsHeaderTop = padding.top + 40 + (60 - lyricsHeaderImageSize) / 2;
    // left = 24 (padding)
    final expandedLyrics = Rect.fromLTWH(
        24.0, lyricsHeaderTop, lyricsHeaderImageSize, lyricsHeaderImageSize);

    return (
    collapsed: collapsed,
    expandedAlbum: expandedAlbum,
    expandedLyrics: expandedLyrics
    );
  }

  Widget _buildMobileBody(_PlayerViewParams params, Rect targetExpandedRect) {
    // 使用 Stack 和 FadeTransition/Opacity 混合实现页面内容的交叉淡入淡出
    return Stack(
      children: [
        // 1. 封面模式内容 (当 lyricsValue 变大时透明度变低)
        Opacity(
          opacity: (1 - params.lyricsValue).clamp(0.0, 1.0),
          child: IgnorePointer(
            ignoring: params.lyricsValue > 0.5,
            child: _buildMobileExpandedContent(context, params.track, targetExpandedRect),
          ),
        ),

        // 2. 歌词模式内容 (当 lyricsValue 变大时透明度变高)
        Opacity(
          opacity: params.lyricsValue.clamp(0.0, 1.0),
          child: IgnorePointer(
            ignoring: params.lyricsValue <= 0.5,
            child: _buildMobileLyricsLayout(params),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBody(_PlayerViewParams params, Rect expandedRect) {
    return _buildDesktopExpandedContent(context, params.track, expandedRect);
  }
  Widget _buildDesktopExpandedContent(BuildContext context, MediaItem? track, Rect imageRect) {
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


  // --- Minibar ---
  Widget _buildCollapsedMinibar(_PlayerViewParams params, double smallSize) {
    // 只有完全收起时才允许点击 Minibar 展开
    // 当完全展开时，Minibar 应该不可见且不可点击
    final bool isInteractive = params.collapsedOpacity > 0.1;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: widget.minHeight,
      child: IgnorePointer(
        ignoring: !isInteractive,
        child: Opacity(
          opacity: params.collapsedOpacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.panelController?.open(),
            child: Row(
              children: [
                // 占位符：给 Floating Image 留位置
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
                _buildMiniControlButtons(ref),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeroImage(_PlayerViewParams params) {
    return Positioned.fromRect(
      rect: params.currentRect,
      child: GestureDetector(
        // 点击图片切换歌词/封面模式
        onTap: () {
          if (params.progress > 0.5 && context.isMobile) {
            _toggleLyrics();
          } else {
            widget.panelController?.open();
          }
        },
        child: Container(
          decoration: BoxDecoration(
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

    // 1. 获取屏幕尺寸和安全区域
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // 2. 计算顶部避让高度 (保持稳定，不随动画跳动)
    // 逻辑：封面图高度 (宽度 * 0.75) + 顶部状态栏 + 额外的头部间距
    // 你可以根据实际 _calculateRects 中的算法微调这里的数值
    final double coverHeight = (size.width * 0.75).clamp(250.0, 350.0); // 与你计算 expandedAlbum 的逻辑保持一致
    final double topContentStart = padding.top + 60.0 + coverHeight + 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3. 计算“剩余可用高度”
        // 屏幕总高度 - (顶部图片区域 + 底部留白)
        final double availableHeight = constraints.maxHeight - topContentStart - 40.0;

        return SingleChildScrollView(
          // 顶部使用 padding 把位置顶下来
          padding: EdgeInsets.only(top: topContentStart, bottom: 40),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            // 4. 关键点：设置最小高度
            // 如果内容很少，强制撑满 availableHeight，从而让 spaceEvenly 生效
            // 如果内容很多（超过 availableHeight），则自动延伸，允许滚动
            constraints: BoxConstraints(
              minHeight: availableHeight > 0 ? availableHeight : 0,
            ),
            child: Column(
              // 5. 垂直方向均匀分布
              // 因为有了 minHeight 撑腰，spaceEvenly 在大屏上会把组件拉得很舒服
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 歌曲信息
                _info(track),

                // 进度条和控制按钮 (这两者通常靠得近一点，所以包在一起)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: PlayerProgressBar(),
                    ),
                    // 给进度条和按钮之间一点固定的间距，避免拉得太开
                    const SizedBox(height: 20),
                    _controls(ref),
                  ],
                ),

                // 音量控制 (位于最下方)
                _volume(ref),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 歌词页布局 ---
  Widget _buildMobileLyricsLayout(_PlayerViewParams params) {
    return Column(
      children: [
        SizedBox(height: params.topPadding + 40),
        // Header Area
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // 【关键点】这里放置一个透明占位符
              // Floating Image 会精确地飞到这个位置
              const SizedBox(width: 50, height: 50),

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
            const PlayModeButton(),
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

class _PlayerViewParams {
  final MediaItem? track;
  final double progress;
  final double lyricsValue; // 新增：歌词动画进度
  final Rect currentRect;
  final double currentRadius;
  final double collapsedOpacity;
  final double expandedOpacity;
  final String coverUrl;
  final double topPadding;

  _PlayerViewParams({
    required this.track,
    required this.progress,
    required this.lyricsValue,
    required this.currentRect,
    required this.currentRadius,
    required this.collapsedOpacity,
    required this.expandedOpacity,
    required this.coverUrl,
    required this.topPadding,
  });
}