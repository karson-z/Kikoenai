import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'custom_bottom_type.dart';
import 'custom_side_sheet_type.dart';

class PlayerPlaylistSheet {
  static void show(BuildContext context) {
    WoltModalSheet.show<void>(
      context: context,

      // 核心逻辑：根据宽度切换样式
      modalTypeBuilder: (_) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 500;

        if (isMobile) {
          return const CustomBottomType() ;
        } else {
          return const CustomSideSheetType();
        }
      },
      pageListBuilder: (modalContext) {
        return [
        SliverWoltModalSheetPage(
          backgroundColor: Colors.white,
          isTopBarLayerAlwaysVisible: true,

          topBarTitle: const Text(
            '当前播放队列',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          mainContentSliversBuilder: (context) => [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),

            SliverToBoxAdapter(
              child: Consumer(
                builder: (_, ref, __) {
                  final notifier = ref.read(playerControllerProvider.notifier);
                  final state = ref.watch(playerControllerProvider);
                  final playList = state.playlist;

                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: playList.length,

                    onReorder: (oldIndex, newIndex) {
                      final updated = [...playList];

                      // Flutter 的 ReorderableListView 规则：如果 oldIndex < newIndex，newIndex 要 -1
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }

                      final item = updated.removeAt(oldIndex);
                      updated.insert(newIndex, item);

                      notifier.replacePlaylist(updated);
                    },

                    itemBuilder: (_, index) {
                      final item = playList[index];

                      return Dismissible(
                        key: ValueKey("dismiss-${item.hashCode}"),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          notifier.removeMediaItemInQueue(index);
                        },

                        child: ListTile(
                          key: ValueKey("tile-${item.hashCode}"),
                          leading: Text('${index + 1}'),
                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(item.artist ?? '未知艺术家', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          // 长按自动触发 reorder
                          onTap: () {
                            notifier.skipTo(index);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        ];
      },
    );
  }
}
