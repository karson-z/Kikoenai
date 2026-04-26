import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import 'package:kikoenai/core/widgets/filter/special_search.dart';
import '../../../features/category/data/model/selector_item.dart';
import '../../../features/category/presentation/viewmodel/provider/category_option_provider.dart';
import '../../../features/category/presentation/viewmodel/provider/filter_search_notifier.dart';
import '../common/kikoenai_dialog.dart';
import 'filter_bottom_panel.dart';
import 'filter_grid_content.dart';
import 'filter_silder_bar.dart';
void showFilterBottomSheet(BuildContext context,WidgetRef ref,FilterModule type) {
  // 假设你的工具类名为 KikoenaiDialog
  KikoenaiDialog.showBottomSheet(
    context: context,
    isScrollControlled: true, // 关键：允许面板高度超过屏幕一半
    useSafeArea: true,        // 适配顶部刘海和底部指示条
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (ctx) {
      // 给底部弹窗设置一个合适的高度，例如屏幕高度的 70%
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: FilterWidget(
                type: type,
                onComplete: () {
                  context.pop();
                  final notifier = ref.read(searchFilterProvider(type).notifier);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
class FilterWidget extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final FilterModule type;

  const FilterWidget({
    super.key,
    required this.onComplete,
    required this.type
  });

  @override
  ConsumerState<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends ConsumerState<FilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SelectorItem> _getCurrentCategoryItems(CategoryType category) {
    switch (category) {
      case CategoryType.tag:
        final tags = ref.watch(tagsProvider).value ?? [];
        return tags.map((e) => e.toSelectorItem()).toList();
      case CategoryType.circle:
        final circles = ref.watch(circlesProvider).value ?? [];
        return circles.map((e) => e.toSelectorItem()).toList();
      case CategoryType.va:
        final vas = ref.watch(vasProvider).value ?? [];
        return vas.map((e) => e.toSelectorItem()).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFilterProvider(widget.type));
    final controller = ref.read(searchFilterProvider(widget.type).notifier);

    final currentCategory = CategoryType.values[state.selectedFilterIndex];

    List<SelectorItem> currentItems = _getCurrentCategoryItems(currentCategory);

    if (state.localSearchKeyword.isNotEmpty) {
      currentItems = currentItems.where((item) {
        return item.label.toLowerCase().contains(state.localSearchKeyword.toLowerCase());
      }).toList();
    }

    Widget rightContent;

    if (currentCategory == CategoryType.special) {
      rightContent = Expanded(
        child: SingleChildScrollView(
          primary: false,
          child: AdvancedFilterPanel(
            selectedTags: state.selectedTags,
            onToggleTag: (type, name) {
              controller.toggleTag(type, name);
            },
            fillColor: const Color(0xFFF9FAFB),
            textColor: const Color(0xFF4B5563),
          ),
        ),
      );
    } else {
      rightContent = TagGridContent(
        items: currentItems,
        selectedTags: state.selectedTags,
        searchController: _searchController,
        onItemToggled: (SelectorItem item) {
          controller.toggleTag(item.type, item.label);
        },
        onSearchChanged: (String value) {
          controller.setLocalSearchKeyword(value);
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SidebarCategoryList(
                categories: CategoryType.values,
                activeCategory: currentCategory,
                onCategorySelected: (CategoryType category) {
                  controller.setFilterIndex(category.index);
                  _searchController.clear();
                },
              ),
              rightContent,
            ],
          ),
        ),
        BottomActionPanel(
          onReset: () {
            controller.resetSelected();
          },
          // 将内部逻辑替换为调用父组件传入的回调
          onComplete: widget.onComplete,
        ),
      ],
    );
  }
}