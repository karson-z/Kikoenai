import 'package:flutter/material.dart';
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
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: const Text(
              '当前播放队列',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            mainContentSliversBuilder: (context) => [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              SliverList.builder(
                itemCount: 30,
                itemBuilder: (_, index) {
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text('歌曲 $index'),
                    subtitle: const Text('艺术家名称'),
                    onTap: () => Navigator.of(modalContext).pop(),
                  );
                },
              ),
            ],
          ),
        ];
      },
    );
  }
}
