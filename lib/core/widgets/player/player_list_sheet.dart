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
        final isMobile = width < 500; // 你可根据设计调整

        if (isMobile) {
          return const CustomBottomType() ;
        } else {
          return const CustomSideSheetType(); // 你自定义的侧边栏类型
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

              // 让 Riverpod 参与
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (_, ref, __) {
                    final state = ref.watch(playerControllerProvider);
                    final playList = state.playlist;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: playList.length,
                      itemBuilder: (_, index) {
                        final item = playList[index];

                        return ListTile(
                          leading: Text('${index + 1}'),
                          title: Text(item.title,style: TextStyle(fontSize: 16)),
                          subtitle: Text(item.artist ?? '未知艺术家',style: TextStyle(fontSize: 12,color: Colors.grey),),
                          onTap: () {
                            // 跳到歌曲
                            ref.read(playerControllerProvider.notifier).skipTo(index);
                            Navigator.of(modalContext).pop();
                          },
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
