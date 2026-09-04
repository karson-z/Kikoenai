import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/filter/special_search.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../features/category/provider/category_option_provider.dart';
import '../loading/lottie_loading.dart';
import 'provider/filter_search_notifier.dart';
import '../common/kikoenai_dialog.dart';
import 'filter_bottom_panel.dart';
import 'filter_grid_content.dart';
import 'filter_silder_bar.dart';

void showFilterBottomSheet(
  BuildContext context,
  WidgetRef ref,
  FilterModule type, {
  bool isShowAction = true,
  VoidCallback? onComplete,
}) {
  // Dismissing a filter sheet is treated as confirming its current selection.
  // Keep this guarded because pressing "完成" also dismisses the route.
  var didComplete = false;
  void complete() {
    if (didComplete) return;
    didComplete = true;
    onComplete?.call();
  }

  KikoenaiDialog.showBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (modalContext) {
      // 使用弹窗自身的 context
      return FractionallySizedBox(
        heightFactor: 0.75, // 使用比例适配，比 MediaQuery 更简洁
        child: Column(
          children: [
            // 顶部 Handle 条
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  modalContext,
                ).dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 内容区域
            Expanded(
              child: FilterWidget(
                type: type,
                isShowAction: isShowAction,
                onComplete: () {
                  // 先关闭弹窗，再执行完成回调，避免回调触发页面重建时使用失效 context。
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }
                  complete();
                },
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) => complete());
}

class FilterWidget extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final FilterModule type;
  final bool isShowAction;
  final Map<CategoryType, List<SelectorItem>>? selectorItemsByCategory;

  const FilterWidget({
    super.key,
    this.isShowAction = true,
    this.selectorItemsByCategory,
    required this.onComplete,
    required this.type,
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

  AsyncValue<List<SelectorItem>> _watchCurrentCategoryItems(
    CategoryType category,
  ) {
    final selectorItems = widget.selectorItemsByCategory;
    if (selectorItems != null) {
      return AsyncData(selectorItems[category] ?? const <SelectorItem>[]);
    }
    switch (category) {
      case CategoryType.tag:
        return ref
            .watch(tagsProvider)
            .whenData((tags) => tags.map((e) => e.toSelectorItem()).toList());
      case CategoryType.circle:
        return ref.watch(circlesProvider).whenData(
              (circles) => circles.map((e) => e.toSelectorItem()).toList(),
            );
      case CategoryType.va:
        return ref
            .watch(vasProvider)
            .whenData((vas) => vas.map((e) => e.toSelectorItem()).toList());
      default:
        return const AsyncData<List<SelectorItem>>([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFilterProvider(widget.type));
    final controller = ref.read(searchFilterProvider(widget.type).notifier);
    final currentCategory = CategoryType.values[state.selectedFilterIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final asyncItems = _watchCurrentCategoryItems(currentCategory);
    // 首次加载（无缓存数据）时显示加载动画，刷新时保留之前数据
    final isLoading = asyncItems.isLoading && !asyncItems.hasValue;
    List<SelectorItem> currentItems = asyncItems.value ?? [];

    if (state.localSearchKeyword.isNotEmpty) {
      currentItems = currentItems.where((item) {
        return item.label.toLowerCase().contains(
              state.localSearchKeyword.toLowerCase(),
            );
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
            fillColor:
                isDark ? const Color(0xFF212529) : const Color(0xFFF9FAFB),
            textColor:
                isDark ? const Color(0xFF8492A6) : const Color(0xFF4B5563),
          ),
        ),
      );
    } else if (isLoading) {
      rightContent = const Expanded(
        child: Center(
          child: LottieLoadingIndicator(size: 76, message: '加载中...'),
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
        if (widget.isShowAction)
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
