import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'dart:ui';
import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../../provider/player_controller_provider.dart';

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
        // 获取当前主题的主色调用于高亮
        final primaryColor = Theme.of(context).primaryColor;

        final minSheetHeight = MediaQuery.of(context).size.height * 0.4;

        Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
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
            hasSabGradient: false,
            topBarTitle: Text(
              '当前播放队列',
              style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
            ),
            mainContentSliversBuilder: (context) => [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              // 弹窗手势拦截
              BackButtonPriorityWrapper(
                zIndex: 100,
                name: 'PlaylistSheetModal',
                child: Consumer(
                  builder: (_, ref, __) {
                    final notifier = ref.read(playerControllerProvider.notifier);
                    final state = ref.watch(playerControllerProvider);
                    final currentTrack = state.currentTrack;
                    final playList = state.playlist;

                    if (playList.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.queue_music, size: 64, color: subtitleColor.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text("播放队列为空", style: TextStyle(color: subtitleColor, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverReorderableList(
                          itemCount: playList.length,
                          proxyDecorator: proxyDecorator,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) newIndex -= 1;
                            notifier.replacePlaylist(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final item = playList[index];
                            final itemKey = ValueKey("tile-${item.hashCode}");
                            final isCurrentTrack = currentTrack != null && item == currentTrack;

                            return ReorderableDelayedDragStartListener(
                              key: itemKey,
                              index: index,
                              child: Slidable(
                                key: ValueKey("slidable-${item.hashCode}"),
                                // groupTag 可以防止多个列表项同时被滑动展开
                                groupTag: 'playlist',
                                // 设置左滑展示的面板 (在右侧)
                                endActionPane: ActionPane(
                                  // ScrollMotion 提供跟随滑动的丝滑动画
                                  motion: const ScrollMotion(),
                                  // 设置按钮占整行的宽度比例，这里设为 20%
                                  extentRatio: 0.2,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        notifier.removeMediaItemInQueue(index);
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: isCurrentTrack
                                      ? Icon(Icons.volume_up_rounded, color: primaryColor)
                                      : Text('${index + 1}', style: TextStyle(color: titleColor)),
                                  title: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrentTrack ? primaryColor : titleColor,
                                      fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.artist ?? '未知艺术家',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCurrentTrack ? primaryColor.withOpacity(0.8) : subtitleColor,
                                    ),
                                  ),
                                  onTap: () {
                                    if (isCurrentTrack) return;
                                    notifier.skipTo(index);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: SizedBox.shrink(), // 不需要显示内容，只负责占位
                        ),
                      ],
                    );
                  },
                ),
              ),
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