import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import 'package:kikoenai/features/category/widget/special_search.dart';
import '../data/model/selector_item.dart';
import '../presentation/viewmodel/provider/category_option_provider.dart';
import 'filter_bottom_panel.dart';
import 'filter_grid_content.dart';
import 'filter_silder_bar.dart';

class FilterWidget extends ConsumerStatefulWidget {
  const FilterWidget({super.key});

  @override
  ConsumerState<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends ConsumerState<FilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialKeyword = ref.read(categoryUiProvider).localSearchKeyword;
    _searchController = TextEditingController(text: initialKeyword);
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
    final state = ref.watch(categoryUiProvider);
    final controller = ref.read(categoryUiProvider.notifier);

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
          child: AdvancedFilterPanel(
            selectedTags: state.selected,
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
        selectedTags: state.selected,
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
          onComplete: () {
            controller.closeFilterDrawer();
            controller.searchImmediately();
          },
        ),
      ],
    );
  }
}