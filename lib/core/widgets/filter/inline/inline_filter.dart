import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../features/category/provider/category_option_provider.dart';
import '../../overlay/top_sheet.dart';
import '../provider/filter_search_notifier.dart';
import '../special_search.dart';
import 'filter_option_card.dart';
import 'filter_summary_area.dart';

/// 收起态筛选横条：常驻页面布局中（AppBar / 工具栏下方），始终存在。
///
/// 点击横条或箭头展开 [FilterDropdownPanel]。
///
/// 面板通过根 Navigator 的 [ModalTopSheetRoute] 展示，顶边与本横条对齐并
/// 向下延伸；遮罩挂在根 Navigator 上，能盖住底部导航栏，但只压暗横条以下
/// 的区域，横条上方的工具栏保持原样。
class InlineFilterBar extends ConsumerWidget {
  const InlineFilterBar({
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

  /// 选项来源覆盖（DL 库使用当前本地作品聚合结果）。
  final Map<CategoryType, List<SelectorItem>>? optionsOverride;

  final bool showSpecialTab;

  /// 清空作品级关键字（页面需附带刷新逻辑时传入）
  final VoidCallback? onClearKeyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFilterProvider(module));
    final notifier = ref.read(searchFilterProvider(module).notifier);
    final tabs = _tabsFor(showSpecialTab);

    void openFilter({int? index}) {
      final targetIndex = index ?? state.selectedFilterIndex;
      notifier.openFilterAt(targetIndex);

      showTopSheet<void>(
        context: context,
        builder: (sheetContext) => FilterDropdownPanel(
          module: module,
          totalCount: totalCount,
          optionsOverride: optionsOverride,
          showSpecialTab: showSpecialTab,
          onClearKeyword: onClearKeyword,
          onClose: () => Navigator.of(sheetContext, rootNavigator: true).pop(),
        ),
      ).whenComplete(notifier.closeFilterDrawer);
    }

    return FilterSummaryArea(
      isExpanded: false,
      selectedTags: state.selectedTags,
      keyword: state.keyword,
      totalCount: totalCount,
      quickEntries: tabs,
      onToggleExpand: openFilter,
      onRemoveTag: (tag) => notifier.removeTag(tag.type, tag.name),
      onClearKeyword: onClearKeyword,
      onReset: notifier.resetSelected,
      onQuickEntryTap: (type) => openFilter(index: tabs.indexOf(type)),
    );
  }
}

/// 展开态筛选面板：从常驻 [InlineFilterBar] 的位置向下延伸出来。
///
/// 顶边与横条对齐，因此看起来是横条本身长出的内容，而非从屏幕顶部盖下；
/// 面板以下的页面内容与底部导航栏被遮罩压暗，横条上方不变。
/// 内容 = 灰底「筛选内容」摘要（两行封顶）+ 维度选项卡片。
/// 展开动画与遮罩由 [ModalTopSheetRoute] 统一管理。
class FilterDropdownPanel extends ConsumerWidget {
  const FilterDropdownPanel({
    super.key,
    required this.module,
    this.totalCount,
    this.optionsOverride,
    this.showSpecialTab = true,
    this.onClearKeyword,
    this.onClose,
  });

  final FilterModule module;

  /// 「共 N 条」命中计数，由宿主页面传入（null 不显示）
  final int? totalCount;

  /// 选项来源覆盖（DL库传本地聚合结果）；某维度聚合为空时该维度回退
  /// 远端 tags/circles/vas providers；null 时全部走远端
  final Map<CategoryType, List<SelectorItem>>? optionsOverride;

  final bool showSpecialTab;

  /// 清空作品级关键字（页面需附带刷新逻辑时传入）
  final VoidCallback? onClearKeyword;

  /// 关闭宿主 TopSheet。直接嵌入测试或预览时为空，则关闭筛选状态。
  final VoidCallback? onClose;

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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 摘要区与上下间距的固定占位；卡片取剩余可用高度，并保留原先
        // 「不超过半屏」的上限，避免面板总高溢出遮罩。
        const double summaryReserve = 136;
        final double available = constraints.maxHeight.isFinite
            ? constraints.maxHeight - summaryReserve
            : screenHeight;
        final double cardHeight = available.clamp(120.0, screenHeight * 0.5);

        return Material(
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
                onToggleExpand: onClose ?? notifier.closeFilterDrawer,
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
        );
      },
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
  // 宿主（DL库）提供的本地聚合选项：有数据时优先使用，聚合出的选项
  // 与本地过滤逻辑严格对应；本地库暂无作品导致聚合为空时，回退到
  // 远端 tags/circles/vas 选项，保证面板各维度不出现空态。
  final List<SelectorItem>? local = override?[type];
  if (local != null && local.isNotEmpty) {
    return AsyncData(local);
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
