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
    // 1. 使用 LayoutBuilder 获取当前父容器的实际可用宽高
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final double imageSize = (width * 0.8)
          .clamp(0.0, height * 0.45)
          .clamp(150.0, 340.0);
      // 3. 判断是否是小屏幕/矮屏幕，如果是，减少垂直间距
      final bool isSmallScreen = height < 600;
      final double gapSmall = isSmallScreen ? 10 : 20;
      final double gapLarge = isSmallScreen ? 15 : 30;

      return Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _topBar(panelControl),

          // --- 中间区域 ---
          Expanded(
            flex: 10,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _showLyrics
                  ? LyricsView(
                key: const ValueKey('lyrics'),
                onTap: _toggleLyrics,
              )
              // 传入计算好的自适应 imageSize
                  : _buildCoverAndInfo(context, imageSize, currentTrack),
            ),
          ),
          // ---------------------------

          SizedBox(height: gapSmall), // 动态间距

          // 进度条
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: PlayerProgressBar(),
          ),

          SizedBox(height: gapSmall), // 进度条和控制栏之间的间距

          _controls(ref),

          SizedBox(height: gapSmall),

          _volume(ref),

          SizedBox(height: gapLarge), // 底部间距
        ],
      );
    });
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      MediaItem? currentTrack,
      PanelController panelControl
      ) {
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
                // 【修改点 1】包裹 Center，确保高度充足时内容垂直居中
                child: Center(
                  // 【修改点 2】包裹 SingleChildScrollView，确保高度不足时可滚动，消除溢出
                  child: SingleChildScrollView(
                    child: Column(
                      // 【修改点 3】设为 min，让 Column 高度随内容自适应，配合 Center 使用
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _cover(imageSize, currentTrack),
                        const SizedBox(height: 40),
                        _info(currentTrack),
                        const SizedBox(height: 30),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 48.0),
                          child: PlayerProgressBar(),
                        ),
                        const SizedBox(height: 30),
                        _controls(ref),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: 300,
                            child: _volume(ref)
                        ),
                        // 底部加一点安全距离，防止滚动到底太贴边
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // 右侧：歌词区 (保持不变)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 32, top: 32, bottom: 32),
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
      key: const ValueKey('cover_info_group'),
      width: double.infinity,
      color: Colors.transparent,
      // 【修改点】包裹一个 SingleChildScrollView
      child: SingleChildScrollView(
        // 设置为 BouncingScrollPhysics 或 ClampingScrollPhysics
        // 这样在没有大幅溢出时不会出现滚动条的视觉干扰
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 封面区域
            GestureDetector(
              onTap: _toggleLyrics,
              child: _cover(imageSize, currentTrack),
            ),

            const SizedBox(height: 28),

            // 信息区域
            _info(currentTrack),
          ],
        ),
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

    // 【修改点】添加 Padding 和 FittedBox
    return Padding(
      // 给左右留一点安全边距，防止贴边
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FittedBox(
        // BoxFit.scaleDown 表示：只有当宽度不足时才缩小，宽度够时保持原大
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
              child: Container(
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
              onPressed: widget.onQueuePressed,
              icon: const Icon(Icons.queue_music_sharp, color: Colors.white),
            ),
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