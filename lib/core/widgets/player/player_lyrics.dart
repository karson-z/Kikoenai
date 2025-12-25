import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 初始化加载歌词
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        ref.read(lyricsProvider.notifier).loadLyrics();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 滚动到指定索引的通用方法
  Future<void> _scrollToIndex(int index) async {
    final isDragging = ref.read(lyricScrollStateProvider);

    // 如果正在拖拽，或者控制器还没绑定好，就不自动滚动
    if (isDragging || !_itemScrollController.isAttached) return;

    try {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // 0.5 表示垂直居中
      );
    } catch (e) {
      debugPrint("Scroll Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    // 监听字幕源变化，重新加载歌词
    ref.listen(
        playerControllerProvider.select((s) => s.subtitleList),
            (previous, next) {
          if (next != previous) {
            ref.read(lyricsProvider.notifier).loadLyrics();
          }
        });

    final lyricsAsync = ref.watch(lyricsProvider);

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
    // 1. 获取屏幕高度
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = screenHeight * 0.15;
    final double bottomPadding = screenHeight / 2;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final notifier = ref.read(lyricScrollStateProvider.notifier);
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
              // 顶部 0.0~0.15 渐变透明，底部 0.85~1.0 渐变透明
              colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ScrollablePositionedList.builder(
            itemCount: lyrics.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: EdgeInsets.only(
                top: topPadding,
                bottom: bottomPadding,
                left: 24,
                right: 24
            ),

            initialScrollIndex: activeIndex,
            initialAlignment: 0.5,

            itemBuilder: (context, index) {
              final line = lyrics[index];
              final isActive = index == activeIndex;
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