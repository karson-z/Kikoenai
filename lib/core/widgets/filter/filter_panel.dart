import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'filter_options.dart';
import 'provider/filter_search_notifier.dart';
import 'widgets/advanced_filter_panel.dart';
import 'widgets/filter_option_card.dart';
import 'widgets/filter_summary_header.dart';

/// 展开态筛选面板的容器：只做数据组装，不画壳。
///
/// 职责：watch 筛选状态与维度选项（[resolveDimensionOptions]）、
/// 应用本地关键字过滤、把 notifier 方法映射成子组件回调，
/// 交给纯展示的 [FilterPanelView] 渲染。
class FilterPanelContainer extends ConsumerWidget {
  const FilterPanelContainer({
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
    final tabs = filterTabsFor(showSpecialTab);
    final activeType =
        tabs[state.selectedFilterIndex.clamp(0, tabs.length - 1)];

    var items = resolveDimensionOptions(
      ref,
      dimension: activeType,
      localAggregation: optionsOverride,
    );
    final keyword = state.localSearchKeyword.trim().toLowerCase();
    if (keyword.isNotEmpty && activeType != CategoryType.special) {
      items = items.whenData((list) => applyLocalKeyword(list, keyword));
    }

    return FilterPanelView(
      totalCount: totalCount,
      tabs: tabs,
      activeType: activeType,
      items: items,
      selectedTags: state.selectedTags,
      keyword: state.keyword,
      onToggleExpand: onClose ?? notifier.closeFilterDrawer,
      onRemoveTag: (tag) => notifier.removeTag(tag.type, tag.name),
      onClearKeyword: onClearKeyword,
      onReset: notifier.resetSelected,
      onTabChanged: (type) => notifier.setFilterIndex(tabs.indexOf(type)),
      onSearchChanged: notifier.setLocalSearchKeyword,
      onOptionTap: (item) => notifier.toggleTag(item.type, item.label),
      onOptionLongPress: (item) => notifier.excludeTag(item.type, item.label),
      onAdvancedToggleTag: notifier.toggleTag,
    );
  }
}

/// 展开态筛选面板的视图：摘要头 + 维度选项卡片的纯内容组合。
/// 纯展示组件，数据与回调全部由 [FilterPanelContainer] 注入。
///
/// 面板的表面（背景/圆角/阴影/裁剪）、整体高度与拖拽手把全部由宿主
/// TopSheet 管控（[showTopSheet] 参数配置）；本组件只按给定高度用
/// [Expanded] 自行分配，需在有界高度内使用。
class FilterPanelView extends StatelessWidget {
  const FilterPanelView({
    super.key,
    required this.totalCount,
    required this.tabs,
    required this.activeType,
    required this.items,
    required this.selectedTags,
    required this.keyword,
    required this.onToggleExpand,
    required this.onRemoveTag,
    required this.onClearKeyword,
    required this.onReset,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onOptionTap,
    required this.onOptionLongPress,
    required this.onAdvancedToggleTag,
  });

  final int? totalCount;
  final List<CategoryType> tabs;
  final CategoryType activeType;
  final AsyncValue<List<SelectorItem>> items;
  final List<SearchTag> selectedTags;
  final String? keyword;

  final VoidCallback onToggleExpand;
  final ValueChanged<SearchTag> onRemoveTag;
  final VoidCallback? onClearKeyword;
  final VoidCallback onReset;
  final ValueChanged<CategoryType> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SelectorItem> onOptionTap;
  final ValueChanged<SelectorItem> onOptionLongPress;
  final Function(String type, String name) onAdvancedToggleTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        FilterSummaryHeader(
          selectedTags: selectedTags,
          keyword: keyword,
          totalCount: totalCount,
          onToggleExpand: onToggleExpand,
          onRemoveTag: onRemoveTag,
          onClearKeyword: onClearKeyword,
          onReset: onReset,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterOptionCard(
              tabs: tabs,
              activeType: activeType,
              items: items,
              selectedTags: selectedTags,
              specialPanel: activeType == CategoryType.special
                  ? AdvancedFilterPanel(
                      selectedTags: selectedTags,
                      onToggleTag: onAdvancedToggleTag,
                      fillColor: isDark
                          ? const Color(0xFF212529)
                          : const Color(0xFFF9FAFB),
                      textColor: isDark
                          ? const Color(0xFF8492A6)
                          : const Color(0xFF4B5563),
                    )
                  : null,
              onTabChanged: onTabChanged,
              onSearchChanged: onSearchChanged,
              onOptionTap: onOptionTap,
              onOptionLongPress: onOptionLongPress,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
