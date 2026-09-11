import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../features/category/provider/category_option_provider.dart';
import '../provider/filter_search_notifier.dart';
import '../special_search.dart';
import 'filter_option_card.dart';
import 'filter_summary_area.dart';

/// 收起态筛选横条：常驻页面布局中（AppBar / 工具栏下方），始终存在。
///
/// 点击横条或箭头展开 [FilterDropdownPanel] —— 面板由宿主页面以覆盖层形式
/// 锚定在 AppBar 底部展示（盖住本横条），配合页面级模态遮罩使用。
class InlineFilterBar extends ConsumerWidget {
  const InlineFilterBar({
    super.key,
    required this.module,
    this.totalCount,
    this.showSpecialTab = true,
    this.onClearKeyword,
  });

  final FilterModule module;

  /// 「共 N 条」命中计数，由宿主页面传入（null 不显示）
  final int? totalCount;

  final bool showSpecialTab;

  /// 清空作品级关键字（页面需附带刷新逻辑时传入）
  final VoidCallback? onClearKeyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFilterProvider(module));
    final notifier = ref.read(searchFilterProvider(module).notifier);
    final tabs = _tabsFor(showSpecialTab);

    return FilterSummaryArea(
      isExpanded: false,
      selectedTags: state.selectedTags,
      keyword: state.keyword,
      totalCount: totalCount,
      quickEntries: tabs,
      onToggleExpand: notifier.toggleFilterDrawer,
      onRemoveTag: (tag) => notifier.removeTag(tag.type, tag.name),
      onClearKeyword: onClearKeyword,
      onReset: notifier.resetSelected,
      onQuickEntryTap: (type) => notifier.openFilterAt(tabs.indexOf(type)),
    );
  }
}

/// 展开态筛选面板：从 AppBar 底部向下展开的覆盖层。
///
/// 盖住常驻的 [InlineFilterBar] 与页面内容，不压缩布局；
/// 内容 = 灰底「筛选内容」摘要（两行封顶）+ 维度选项卡片。
/// 由宿主页面配合全局模态遮罩一起展示。
class FilterDropdownPanel extends ConsumerWidget {
  const FilterDropdownPanel({
    super.key,
    required this.module,
    this.totalCount,
    this.optionsOverride,
    this.showSpecialTab = true,
    this.onClearKeyword,
  });

  final FilterModule module;

  /// 「共 N 条」命中计数，由宿主页面传入（null 不显示）
  final int? totalCount;

  /// 选项来源覆盖（DL库传本地聚合结果）；null 时走远端 tags/circles/vas providers
  final Map<CategoryType, List<SelectorItem>>? optionsOverride;

  final bool showSpecialTab;

  /// 清空作品级关键字（页面需附带刷新逻辑时传入）
  final VoidCallback? onClearKeyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFilterProvider(module));
    final notifier = ref.read(searchFilterProvider(module).notifier);
    final tabs = _tabsFor(showSpecialTab);
    final activeType =
        tabs[state.selectedFilterIndex.clamp(0, tabs.length - 1)];

    var items = _resolveItems(ref, type: activeType, override: optionsOverride);
    final keyword = state.localSearchKeyword.trim().toLowerCase();
    if (keyword.isNotEmpty && activeType != CategoryType.special) {
      items = items.whenData((list) => _applyKeyword(list, keyword));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardHeight = MediaQuery.sizeOf(context).height * 0.5;

    // 面板从 AppBar 底部向下滑入
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) => ClipRect(
        child: FractionalTranslation(translation: offset, child: child),
      ),
      child: Material(
        color: isDark ? Colors.black : Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterSummaryArea(
              isExpanded: true,
              selectedTags: state.selectedTags,
              keyword: state.keyword,
              totalCount: totalCount,
              quickEntries: tabs,
              onToggleExpand: notifier.toggleFilterDrawer,
              onRemoveTag: (tag) => notifier.removeTag(tag.type, tag.name),
              onClearKeyword: onClearKeyword,
              onReset: notifier.resetSelected,
              onQuickEntryTap: (type) =>
                  notifier.openFilterAt(tabs.indexOf(type)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: cardHeight,
                child: FilterOptionCard(
                  tabs: tabs,
                  activeType: activeType,
                  items: items,
                  selectedTags: state.selectedTags,
                  specialPanel: activeType == CategoryType.special
                      ? AdvancedFilterPanel(
                          selectedTags: state.selectedTags,
                          onToggleTag: notifier.toggleTag,
                          fillColor: isDark
                              ? const Color(0xFF212529)
                              : const Color(0xFFF9FAFB),
                          textColor: isDark
                              ? const Color(0xFF8492A6)
                              : const Color(0xFF4B5563),
                        )
                      : null,
                  onTabChanged: (type) =>
                      notifier.setFilterIndex(tabs.indexOf(type)),
                  onSearchChanged: notifier.setLocalSearchKeyword,
                  onOptionTap: (item) =>
                      notifier.toggleTag(item.type, item.label),
                  onOptionLongPress: (item) =>
                      notifier.excludeTag(item.type, item.label),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

List<CategoryType> _tabsFor(bool showSpecialTab) {
  return showSpecialTab
      ? CategoryType.values
      : CategoryType.values.where((t) => t != CategoryType.special).toList();
}

AsyncValue<List<SelectorItem>> _resolveItems(
  WidgetRef ref, {
  required CategoryType type,
  required Map<CategoryType, List<SelectorItem>>? override,
}) {
  if (override != null) {
    return AsyncData(override[type] ?? const <SelectorItem>[]);
  }
  switch (type) {
    case CategoryType.tag:
      return ref
          .watch(tagsProvider)
          .whenData((tags) => tags.map((e) => e.toSelectorItem()).toList());
    case CategoryType.circle:
      return ref
          .watch(circlesProvider)
          .whenData(
            (circles) => circles.map((e) => e.toSelectorItem()).toList(),
          );
    case CategoryType.va:
      return ref
          .watch(vasProvider)
          .whenData((vas) => vas.map((e) => e.toSelectorItem()).toList());
    case CategoryType.special:
      return const AsyncData(<SelectorItem>[]);
  }
}

List<SelectorItem> _applyKeyword(List<SelectorItem> items, String keyword) {
  return items
      .where((e) => e.label.toLowerCase().contains(keyword))
      .toList(growable: false);
}
