import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // 【必须】使用此库
import 'package:kikoenai/core/widgets/player/provider/player_lyrics_provider.dart';
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
    if (isDragging || !_itemScrollController.isAttached) return;

    try {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.1
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

        const double verticalPadding = 24.0;

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
            return true; // 拦截通知，防止 SlidingUpPanel 冲突
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
                  stops: [0.0, 0.15, 0.85, 1.0], // 稍微调整渐变范围，让中间显示更多
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ScrollablePositionedList.builder(
                itemCount: lyrics.length,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: verticalPadding,
                    bottom: verticalPadding
                ),
                initialScrollIndex: activeIndex,
                initialAlignment: 0.0,
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