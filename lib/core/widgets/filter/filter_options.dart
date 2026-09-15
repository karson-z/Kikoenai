import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'provider/site_option_providers.dart';

/// 面板维度 Tab 顺序（[showSpecialTab] 为 false 时去掉「特殊」维度）。
List<CategoryType> filterTabsFor(bool showSpecialTab) {
  return showSpecialTab
      ? CategoryType.values
      : CategoryType.values.where((t) => t != CategoryType.special).toList();
}

/// 解析某个维度应展示的选项列表——筛选面板选项数据的唯一出口。
///
/// 优先级：
/// 1. 本地聚合（DL库从本地作品聚合而来，与本地过滤逻辑严格对应）；
/// 2. 聚合为空时回退远端 tags/circles/vas providers，保证维度不出现空态；
/// 3. 「特殊」维度没有网格选项（由 AdvancedFilterPanel 静态渲染）。
AsyncValue<List<SelectorItem>> resolveDimensionOptions(
  WidgetRef ref, {
  required CategoryType dimension,
  Map<CategoryType, List<SelectorItem>>? localAggregation,
}) {
  final List<SelectorItem>? local = localAggregation?[dimension];
  if (local != null && local.isNotEmpty) {
    return AsyncData(local);
  }
  switch (dimension) {
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

/// 面板内搜索框的本地关键字过滤（按选项标签包含匹配，大小写不敏感）。
///
/// [keyword] 需已 trim + toLowerCase。
List<SelectorItem> applyLocalKeyword(List<SelectorItem> items, String keyword) {
  return items
      .where((e) => e.label.toLowerCase().contains(keyword))
      .toList(growable: false);
}
