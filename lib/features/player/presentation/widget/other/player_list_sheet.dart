import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../../provider/player_controller_provider.dart';

class PlayerPlaylistSheet {
  static Future<void> show(
      BuildContext context, {
        VoidCallback? onClosed,
      }) {
    return WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: (_) {
        final width = MediaQuery.sizeOf(context).width;
        return width < 500 ? const CustomBottomType() : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) {
        final colorScheme = Theme.of(modalContext).colorScheme;

        return [
          SliverWoltModalSheetPage(
            isTopBarLayerAlwaysVisible: true,
            hasSabGradient: false,
            topBar: const Center(
              child: Text(
                '当前播放队列',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            mainContentSliversBuilder: (context) => [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              BackButtonPriorityWrapper(
                zIndex: 100,
                name: 'PlaylistSheetModal',
                child: Consumer(
                  builder: (_, ref, __) {
                    final notifier = ref.read(playerControllerProvider.notifier);
                    final state = ref.watch(playerControllerProvider);
                    final currentTrack = state.currentTrack;
                    final playList = state.playlist;

                    // 空状态
                    if (playList.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.queue_music, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("播放队列为空", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    // 列表状态
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverReorderableList(
                          itemCount: playList.length,
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
                                groupTag: 'playlist',
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  extentRatio: 0.2,
                                  children: [
                                    SlidableAction(
                                        onPressed: (context) {
                                          notifier.removeMediaItemInQueue(index);
                                        },
                                        backgroundColor: colorScheme.error,
                                        foregroundColor: colorScheme.onError,
                                        icon: Icons.delete
                                    ),
                                  ],
                                ),
                                child: Material(
                                  child: ListTile(
                                    leading: isCurrentTrack
                                        ? Icon(Icons.volume_up_rounded, color: colorScheme.primary)
                                        : Text('${index + 1}'),
                                    title: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCurrentTrack ? colorScheme.primary : null,
                                        fontWeight: isCurrentTrack ? FontWeight.bold : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.artist ?? '未知艺术家',
                                      style: TextStyle(
                                        color: isCurrentTrack ? colorScheme.primary.withAlpha(200) : null,
                                      ),
                                    ),
                                    onTap: () {
                                      if (isCurrentTrack) return;
                                      notifier.skipTo(index);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                              ),
                            );
                          },
                        ),
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: SizedBox.shrink(),
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