import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 引入你的 Provider、状态类和枚举
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import '../data/model/selector_item.dart';
import '../presentation/viewmodel/provider/category_option_provider.dart';
import 'filter_bottom_panel.dart';
import 'filter_grid_content.dart';
import 'filter_silder_bar.dart';


/// 全局共享的筛选面板组件
class FilterWidget extends ConsumerStatefulWidget {
  const FilterWidget({super.key});

  @override
  ConsumerState<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends ConsumerState<FilterWidget> {
  // 管理搜索框状态
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 初始化时从 state 中读取当前的本地搜索词
    final initialKeyword = ref.read(categoryUiProvider).localSearchKeyword;
    _searchController = TextEditingController(text: initialKeyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 根据当前选中的左侧索引，获取对应的数据并转为 SelectorItem
  List<SelectorItem> _getCurrentCategoryItems(int index) {
    switch (index) {
      case 0:
        final tags = ref.watch(tagsProvider).value ?? [];
        return tags.map((e) => e.toSelectorItem()).toList();
      case 1:
        final circles = ref.watch(circlesProvider).value ?? [];
        return circles.map((e) => e.toSelectorItem()).toList();
      case 2:
        final vas = ref.watch(vasProvider).value ?? [];
        return vas.map((e) => e.toSelectorItem()).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听状态和获取操作器
    final state = ref.watch(categoryUiProvider);
    final controller = ref.read(categoryUiProvider.notifier);

    // 1. 获取原始数据
    List<SelectorItem> currentItems = _getCurrentCategoryItems(state.selectedFilterIndex);

    // 2. 根据本地搜索词进行前端过滤
    if (state.localSearchKeyword.isNotEmpty) {
      currentItems = currentItems.where((item) {
        return item.label.toLowerCase().contains(state.localSearchKeyword.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧侧边栏
              SidebarCategoryList(
                categories: CategoryType.values,
                // 根据索引反推当前的 CategoryType
                activeCategory: CategoryType.values[state.selectedFilterIndex],
                onCategorySelected: (CategoryType category) {
                  // 切换分类
                  controller.setFilterIndex(category.index);
                  // 切换分类时清空搜索框
                  _searchController.clear();
                },
              ),

              // 右侧内容区（必须加 Expanded，否则 GridView 会报错）
              TagGridContent(
                items: currentItems,
                selectedTags: state.selected, // 传入已选中的标签列表 (SearchTag)
                searchController: _searchController,
                onItemToggled: (SelectorItem item) {
                  controller.toggleTag(item.type, item.label);
                },
                onSearchChanged: (String value) {
                  // 更新本地搜索词状态
                  controller.setLocalSearchKeyword(value);
                },
              ),
            ],
          ),
        ),

        // 固定底部按钮
        BottomActionPanel(
          onReset: () {
            controller.resetSelected();
          },
          onComplete: () {
            controller.closeFilterDrawer();
            controller.searchImmediately();
          },
        ),
      ],
    );
  }
}