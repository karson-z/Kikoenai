import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/player_lyrics.dart';
import 'package:kikoenai/core/widgets/player/player_progress_bar.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../constants/app_images.dart';
import '../../utils/data/colors_util.dart';
import '../image_box/simple_extended_image.dart';
import '../layout/app_main_scaffold.dart';
import '../layout/provider/main_scaffold_provider.dart';

class MusicPlayerView extends ConsumerStatefulWidget {
  final VoidCallback? onQueuePressed;
  const MusicPlayerView({super.key, this.onQueuePressed});

  @override
  ConsumerState<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends ConsumerState<MusicPlayerView> {
  // 控制移动端视图切换：false=封面, true=歌词
  bool _showLyrics = false;

  void _toggleLyrics() {
    setState(() {
      _showLyrics = !_showLyrics;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(
      playerControllerProvider.select((s) => s.currentTrack),
    );
    final panelControl = ref.read(panelController);
    // 监听主图变化，如果变化提取颜色
    ref.listen<String?>(
      playerControllerProvider.select(
            (s) => s.currentTrack?.extras?['mainCoverUrl'] as String?,
      ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 简单的断点判断，宽度大于 800 视为桌面端/宽屏
        final isDesktop = constraints.maxWidth > 800;

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SizedBox.expand(
            child: isDesktop
                ? _buildDesktopLayout(context, currentTrack, panelControl)
                : _buildMobileLayout(context, currentTrack, panelControl),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
      BuildContext context,
      MediaItem? currentTrack,
      PanelController panelControl,
      ) {
    final width = MediaQuery.of(context).size.width;
    final imageSize = width.clamp(260, 340).toDouble();

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        _topBar(panelControl),
        // --- 中间区域：核心切换逻辑 ---
        Expanded(
          flex: 10,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            // 使用 switchInCurve 和 switchOutCurve 让切换更顺滑
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _showLyrics
                ? LyricsView(
              key: const ValueKey('lyrics'),
              onTap: _toggleLyrics, // 点击歌词切回封面
            )
                : _buildCoverAndInfo(context, imageSize, currentTrack), // 封装封面+信息
          ),
        ),
        // ---------------------------

        const SizedBox(height: 20),

        // 进度条 (保持在底部固定区域，不随歌词切换消失)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: PlayerProgressBar(),
        ),

        const Spacer(),
        _controls(ref),
        const SizedBox(height: 20),
        _volume(ref),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      MediaItem? currentTrack,
      PanelController panelControl
      ) {
    // 桌面端封面尺寸可以固定或稍大
    const imageSize = 350.0;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 10),
        _topBar(panelControl),

        Expanded(
          child: Row(
            children: [
              // 左侧：封面 + 控制区
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _cover(imageSize, currentTrack),
                    const SizedBox(height: 40),
                    _info(currentTrack),
                    const SizedBox(height: 30),
                    // 桌面端进度条可以放在左侧，也可以放底部，这里放在左侧示例
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48.0),
                      child: PlayerProgressBar(),
                    ),
                    const SizedBox(height: 30),
                    _controls(ref),
                    const SizedBox(height: 20),
                    // 限制音量条宽度
                    SizedBox(
                        width: 300,
                        child: _volume(ref)
                    ),
                  ],
                ),
              ),

              // 右侧：歌词区
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 32, top: 32, bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.black12, // 可选：给歌词区加一点背景区分
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // 桌面端歌词不需要点击切换，一直显示
                  child: const LyricsView(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _topBar(PanelController panelControl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: panelControl.close,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 30),
          ),
          Text("正在播放",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
          const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }
  Widget _buildCoverAndInfo(BuildContext context, double imageSize, MediaItem? currentTrack) {
    return Container(
      key: const ValueKey('cover_info_group'), // 关键：给 AnimatedSwitcher 识别的 Key
      width: double.infinity,
      color: Colors.transparent, // 确保点击空白处也能响应（如果需要）
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2), // 顶部弹簧

          // 封面区域
          GestureDetector(
            onTap: _toggleLyrics, // 点击封面切换
            child: _cover(imageSize, currentTrack),
          ),

          const SizedBox(height: 28), // 封面和文字的间距

          // 信息区域 (现在包含在切换组里了)
          _info(currentTrack),

          const Spacer(flex: 3), // 底部弹簧，通常底部留白比顶部多一点视觉上更平衡
        ],
      ),
    );
  }

  Widget _cover(double size, MediaItem? track) {
    final cover = track?.extras?['mainCoverUrl'] ?? placeholderImage; // 确保 placeholderImage 可访问
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), //稍微调低阴影
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SimpleExtendedImage(
          cover,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _info(MediaItem? track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(track?.title ?? "没有播放的曲目",
              textAlign: TextAlign.center, // 居中对齐适应不同布局
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final isFirst = ref.watch(playerControllerProvider.select((s) => s.isFirst));
    final isLast = ref.watch(playerControllerProvider.select((s) => s.isLast));

    return Row( // 去掉 padding，由外部控制
      mainAxisAlignment: MainAxisAlignment.center, // 居中
      children: [
        IconButton(
          onPressed: () => controller.setRepeat(AudioServiceRepeatMode.none),
          icon: const Icon(Icons.repeat, color: Colors.white),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: isFirst ? null : controller.previous,
          icon: const Icon(Icons.skip_previous_rounded,
              color: Colors.white, size: 36),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => playing ? controller.pause() : controller.play(),
          child: Container( // 加个圆圈背景更好看
            padding: const EdgeInsets.all(8),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: isLast ? null : controller.next,
          icon: const Icon(Icons.skip_next_rounded,
              color: Colors.white, size: 36),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: widget.onQueuePressed, // 使用 widget.onQueuePressed
          icon: const Icon(Icons.queue_music_sharp, color: Colors.white),
        ),
      ],
    );
  }

  Widget _volume(WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final volume = ref.watch(playerControllerProvider.select((s) => s.volume));

    return Row( // 去掉 Padding，由外部控制
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 150, // 限制滑块宽度
          child: SliderTheme( // 自定义 Slider 样式让它更细
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: controller.setVolume,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
            ),
          ),
        ),
      ],
    );
  }
}