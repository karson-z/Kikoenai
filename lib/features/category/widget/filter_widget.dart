import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';

import 'filter_bottom_panel.dart';
import 'filter_grid_content.dart';
import 'filter_silder_bar.dart';
/// TODO 完成之后迁移到core 下， 作为全局共享组件使用
class FilterWidget extends ConsumerWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryUiProvider);
    final controller = ref.read(categoryUiProvider.notifier);
    return Column(
      // 上下布局 ， 上为内容区 ，下为固定底部按钮
      mainAxisAlignment: .start,
      children: [
        Row(
          // 左右分栏
          children: [
            // 左侧侧边栏
            SidebarCategoryList(
              categories: [],
              activeCategory: null,
              onCategorySelected: (CategoryType value) {},
            ),
            // 右侧内容区
            TagGridContent(
              items: [],
              selectedTags: [],
              searchController: null,
              onItemToggled: (SelectorItem value) {},
              onSearchChanged: (String value) {},
            ),
          ],
        ),
        BottomActionPanel(onReset: () {}, onComplete: () {}),
      ],
    );
  }
}
