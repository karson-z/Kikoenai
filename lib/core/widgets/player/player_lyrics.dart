import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart'; // 用于监听鼠标滚轮
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // 1. 引入新库

// 假设这些是你项目中的其他文件导入
import 'package:kikoenai/core/widgets/player/provider/lyrics_provider.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import '../../model/lyric_model.dart';

class LyricsView extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const LyricsView({Key? key, this.onTap}) : super(key: key);

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> with AutomaticKeepAliveClientMixin {
  // 2. 替换 Controller
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(lyricsProvider.notifier).loadLyrics();
      if (mounted) {
        // 初始定位
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = ref.read(currentLyricIndexProvider);
          _scrollToIndex(index);
        });
      }
    });
  }

  @override
  void dispose() {
    // ItemScrollController 不需要 dispose
    super.dispose();
  }

  Future<void> _scrollToIndex(int index) async {
    final isDragging = ref.read(lyricScrollStateProvider);

    // 检查是否正在拖拽，以及 controller 是否已绑定
    if (isDragging || !_itemScrollController.isAttached) return;

    // 3. 使用新库的滚动 API
    try {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // 【核心】0.5 表示将 item 的中心对齐到视窗的中心
      );
    } catch (e) {
      debugPrint("Scroll Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 监听切歌
    ref.listen(
        playerControllerProvider.select((s) => s.currentTrack),
            (previous, next) {
          if (next != previous && next != null) {
            ref.read(lyricsProvider.notifier).loadLyrics();
          }
        });

    final lyricsAsync = ref.watch(lyricsProvider);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    // 监听拖拽状态结束 -> 恢复位置
    ref.listen<bool>(lyricScrollStateProvider, (previous, isDragging) {
      if (previous == true && isDragging == false) {
        // 拖拽结束，获取最新 index 立即回正
        final latestIndex = ref.read(currentLyricIndexProvider);
        _scrollToIndex(latestIndex);
      }
    });

    // 监听索引变化 -> 自动滚动
    ref.listen<int>(currentLyricIndexProvider, (previous, next) {
      final isDragging = ref.read(lyricScrollStateProvider);
      if (previous != next && !isDragging) {
        _scrollToIndex(next);
      }
    });

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: lyricsAsync.when(
          loading: () => const CupertinoActivityIndicator(color: Colors.white),
          error: (err, stack) => Center(
            child: Text("获取歌词失败", style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          data: (lyrics) {
            if (lyrics.isEmpty) {
              return Center(
                child: Text("暂无歌词", style: TextStyle(color: Colors.white.withOpacity(0.6))),
              );
            }
            return _buildLyricsList(lyrics, activeIndex);
          },
        ),
      ),
    );
  }

  Widget _buildLyricsList(List<LyricsLineModel> lyrics, int activeIndex) {
    // 为了让第一行和最后一行也能居中，Padding 依然需要很大
    // 但 ScrollablePositionedList 处理 padding 的方式更智能，通常建议设置为视窗的一半
    final double verticalPadding = MediaQuery.of(context).size.height / 2.2;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final notifier = ref.read(lyricScrollStateProvider.notifier);

        // 触屏/触控板拖拽逻辑
        if (notification is ScrollStartNotification) {
          if (notification.dragDetails != null) {
            notifier.startDragging();
          }
        } else if (notification is ScrollEndNotification) {
          if (ref.read(lyricScrollStateProvider)) {
            notifier.stopDragging();
          }
        }
        return false;
      },
      // 电脑端鼠标滚轮支持
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final notifier = ref.read(lyricScrollStateProvider.notifier);
            notifier.startDragging();
            notifier.stopDragging();
          }
        },
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          // 4. 替换 ListView 为 ScrollablePositionedList
          child: ScrollablePositionedList.builder(
            itemCount: lyrics.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 24),
            // minCacheExtent: 1000, // 可选：如果你觉得滚动有卡顿，可以开启这个
            itemBuilder: (context, index) {
              final line = lyrics[index];
              final isActive = index == activeIndex;

              // 5. 不再需要 AutoScrollTag，直接返回 Item
              return _buildLyricItem(line, isActive);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLyricItem(LyricsLineModel line, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          if (line.hasMain)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                fontSize: isActive ? 22 : 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              child: Text(line.mainText!),
            ),
          if (line.hasExt) ...[
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.white.withOpacity(0.3),
                fontSize: isActive ? 15 : 13,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              child: Text(line.extText!),
            ),
          ]
        ],
      ),
    );
  }
}