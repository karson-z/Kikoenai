import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // 【必须】使用此库
import 'package:kikoenai/core/widgets/player/provider/lyrics_provider.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import '../../model/lyric_model.dart';

class LyricsView extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  // 虽然接收了 controller，但在 ScrollablePositionedList 中我们不直接绑定它
  // 因为该库与 SlidingUpPanel 的 controller 兼容性极差
  final ScrollController? controller;

  const LyricsView({
    Key? key,
    this.onTap,
    this.controller,
  }) : super(key: key);

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        ref.read(lyricsProvider.notifier).loadLyrics();
      }
    });
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
        // 【关键】：0.5 表示将该 Item 的中心点对齐到列表视窗的中心点
        alignment: 0.5,
      );
    } catch (e) {
      debugPrint("Scroll Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    ref.listen(
        playerControllerProvider.select((s) => s.subtitleList),
            (previous, next) {
          if (next != previous) {
            ref.read(lyricsProvider.notifier).loadLyrics();
          }
        });

    final lyricsAsync = ref.watch(lyricsProvider);

    ref.listen<bool>(lyricScrollStateProvider, (previous, isDragging) {
      if (previous == true && isDragging == false) {
        final latestIndex = ref.read(currentLyricIndexProvider);
        _scrollToIndex(latestIndex);
      }
    });

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
    // 使用 LayoutBuilder 获取真实高度
    return LayoutBuilder(
      builder: (context, constraints) {
        // [修复逻辑错误]：原代码是 constraints.maxHeight * 0.04，这会导致 listHeight 非常小，
        // 进而导致 verticalPadding 极小，无法实现中间居中。
        // 这里应该直接使用 maxHeight 获取容器完整高度。
        final double listHeight = constraints.maxHeight * 0.04;

        // 垂直 Padding 设为高度的一半，确保 index 0 能居中
        final double verticalPadding = listHeight / 2;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final notifier = ref.read(lyricScrollStateProvider.notifier);

            // 1. 保持原有的拖拽状态检测逻辑
            if (notification is ScrollStartNotification) {
              if (notification.dragDetails != null) {
                notifier.startDragging();
              }
            } else if (notification is ScrollEndNotification) {
              if (ref.read(lyricScrollStateProvider)) {
                notifier.stopDragging();
              }
            }

            // 2. 【核心修改】：返回 true !!!
            // 在 Flutter 中，返回 true 表示 "通知已被处理，不再向父组件冒泡"。
            // 这样 SlidingUpPanel 就收不到 ScrollNotification，
            // 它就不会尝试去接管手势，从而彻底解决了冲突。
            return true;
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
                  colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.08, 0.92, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ScrollablePositionedList.builder(
                itemCount: lyrics.length,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,

                // 【核心修改】：使用 BouncingScrollPhysics
                // 配合上面的 return true，Bouncing 效果能让列表在拉到边缘时
                // 继续消耗手势动量，而不是把手势交还给父组件。
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),

                padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: verticalPadding,
                    bottom: verticalPadding
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
      },
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