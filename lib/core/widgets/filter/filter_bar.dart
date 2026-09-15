import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../overlay/top_sheet.dart';
import 'filter_options.dart';
import 'filter_panel.dart';
import 'provider/filter_search_notifier.dart';
import 'widgets/collapsed_filter_bar.dart';

/// 筛选入口容器：宿主页面与筛选系统的唯一接触点。
///
/// 职责：watch 筛选状态、在点击时通过根 Navigator 的 [ModalTopSheetRoute]
/// 弹出 [FilterPanelContainer]、把 notifier 方法映射成横条回调。
/// 本组件是筛选域内唯一感知 [showTopSheet] 的地方；自身不画 UI，
/// 收起态外观由纯展示的 [CollapsedFilterBar] 渲染。
///
/// 面板顶边与本横条对齐并向下延伸；遮罩挂在根 Navigator 上，
/// 能盖住底部导航栏，但只压暗横条以下的区域。
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

  /// 选项来源覆盖（DL库传本地聚合结果）；某维度聚合为空时该维度回退
  /// 远端 tags/circles/vas providers；null 时全部走远端
  final Map<CategoryType, List<SelectorItem>>? optionsOverride;

  final bool showSpecialTab;

  /// 清空作品级关键字（页面需附带刷新逻辑时传入）
  final VoidCallback? onClearKeyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFilterProvider(module));
    final notifier = ref.read(searchFilterProvider(module).notifier);
    final tabs = filterTabsFor(showSpecialTab);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void openFilter({int? index}) {
      final targetIndex = index ?? state.selectedFilterIndex;
      notifier.openFilterAt(targetIndex);

      // 面板形状/高度由 TopSheet 管控，这里只做配置：
      // 表面沿用「黑/白 + 海拔8 + 底部圆角16(默认)」，高度沿用原
      // 「摘要 + 半屏卡片」的量级（约 0.68 屏高封顶）。
      showTopSheet<void>(
        context: context,
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        clipBehavior: Clip.antiAlias,
        maxHeightFactor: 0.68,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(26),
          ),
        ),


        builder: (sheetContext) => FilterPanelContainer(
          module: module,
          totalCount: totalCount,
          optionsOverride: optionsOverride,
          showSpecialTab: showSpecialTab,
          onClearKeyword: onClearKeyword,
          onClose: () => Navigator.of(sheetContext, rootNavigator: true).pop(),
        ),
      ).whenComplete(notifier.closeFilterDrawer);
    }

    return CollapsedFilterBar(
      selectedTags: state.selectedTags,
      keyword: state.keyword,
      totalCount: totalCount,
      quickEntries: tabs,
      onToggleExpand: () => openFilter(),
      onRemoveTag: (tag) => notifier.removeTag(tag.type, tag.name),
      onClearKeyword: onClearKeyword,
      onQuickEntryTap: (type) => openFilter(index: tabs.indexOf(type)),
    );
  }
}
