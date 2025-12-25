import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'dart:ui';
import 'custom_bottom_type.dart';
import 'custom_side_sheet_type.dart';


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
        return isMobile ? const CustomBottomType() : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) {
        final isDarkMode = isDark ?? false;
        final bgColor = isDarkMode ? Colors.black : Colors.white;
        final titleColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.white70 : Colors.grey;

        Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
              return Material(
                elevation: lerpDouble(0, 6, animValue)!,
                color: bgColor, // 保持和列表背景一致
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

              // 使用 Consumer 包裹整个 SliverReorderableList
              Consumer(
                builder: (_, ref, __) {
                  final notifier = ref.read(playerControllerProvider.notifier);
                  final state = ref.watch(playerControllerProvider);
                  final playList = state.playlist;

                  // [修改点 1]: 使用 SliverReorderableList
                  return SliverReorderableList(
                    itemCount: playList.length,
                    proxyDecorator: proxyDecorator, // 设置拖拽样式
                    onReorder: (oldIndex, newIndex) {
                      final updated = [...playList];
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = updated.removeAt(oldIndex);
                      updated.insert(newIndex, item);
                      notifier.replacePlaylist(updated);
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => notifier.removeMediaItemInQueue(index),
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
                              style: TextStyle(fontSize: 12, color: subtitleColor),
                            ),
                            onTap: () {
                              notifier.skipTo(index);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // 底部留白，防止最后一条被遮挡（可选）
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