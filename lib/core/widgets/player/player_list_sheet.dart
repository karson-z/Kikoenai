import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'dart:math' as math; // 引入 math 用于计算 max
import 'dart:ui';
import '../common/custom_bottom_type.dart';
import '../common/custom_side_sheet_type.dart';

class PlayerPlaylistSheet {
  static Future<void> show(
      BuildContext context, {
        bool? isDark,
        VoidCallback? onClosed,
      }) {
    return WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: (_) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 500;
        return isMobile
            ? const CustomBottomType()
            : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) {
        final isDarkMode = isDark ?? false;
        final bgColor = isDarkMode ? Colors.black : Colors.white;
        final titleColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.white70 : Colors.grey;

        // 设定最小高度 (例如屏幕高度的 40%)
        final minSheetHeight = MediaQuery.of(context).size.height * 0.4;

        Widget proxyDecorator(
            Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue =
              Curves.easeInOut.transform(animation.value);
              return Material(
                elevation: lerpDouble(0, 6, animValue)!,
                color: bgColor,
                shadowColor: Colors.black26,
                child: child,
              );
            },
            child: child,
          );
        }

        return [
          SliverWoltModalSheetPage(
            backgroundColor: bgColor,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: Text(
              '当前播放队列',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            mainContentSliversBuilder: (context) => [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              Consumer(
                builder: (_, ref, __) {
                  final notifier = ref.read(playerControllerProvider.notifier);
                  final state = ref.watch(playerControllerProvider);
                  final playList = state.playlist;
                  if (playList.isEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: minSheetHeight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue_music,
                                size: 64,
                                color: subtitleColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "播放队列为空",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      // 2.1 真实的列表
                      SliverReorderableList(
                        itemCount: playList.length,
                        proxyDecorator: proxyDecorator,
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) newIndex -= 1;
                          notifier.replacePlaylist(oldIndex,newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = playList[index];
                          final itemKey = ValueKey("tile-${item.hashCode}");

                          return ReorderableDelayedDragStartListener(
                            key: itemKey,
                            index: index,
                            child: Dismissible(
                              key: ValueKey("dismiss-${item.hashCode}"),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) =>
                                  notifier.removeMediaItemInQueue(index),
                              child: ListTile(
                                leading: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: titleColor),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: titleColor),
                                ),
                                subtitle: Text(
                                  item.artist ?? '未知艺术家',
                                  style: TextStyle(
                                      fontSize: 12, color: subtitleColor),
                                ),
                                onTap: () {
                                  notifier.skipTo(index);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final paintedHeight = constraints.precedingScrollExtent;
                          final remainingHeight = minSheetHeight - paintedHeight;
                          return SliverToBoxAdapter(
                            child: SizedBox(
                              height: math.max(0, remainingHeight),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              // 底部安全留白
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ];
      },
    ).whenComplete(() {
      if (onClosed != null) onClosed();
    });
  }
}