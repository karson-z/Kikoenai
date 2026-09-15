import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'filter_chip.dart';

/// 已选 chip 的统一高度。
const double kFilterChipHeight = 28;

/// 展开态筛选摘要头：灰底「筛选内容」标题行（已选计数/重置/收起箭头）
/// + 两行封顶的已选 chips（Wrap，超出在区域内部滚动）。
/// 纯展示组件，不依赖任何 provider。
///
/// 收起态横条见 [CollapsedFilterBar]；
/// 两种形态通过 [buildSelectedFilterChips] 共享同一份已选 chip 构建规则，
/// 保证收起/展开展示的已选内容一致。
class FilterSummaryHeader extends StatelessWidget {
  const FilterSummaryHeader({
    super.key,
    required this.selectedTags,
    this.keyword,
    this.totalCount,
    required this.onToggleExpand,
    required this.onRemoveTag,
    this.onClearKeyword,
    required this.onReset,
  });

  final List<SearchTag> selectedTags;

  /// 作品级搜索关键字，非空时作为第一个 chip 展示
  final String? keyword;

  /// 「共 N 条」命中计数，无已选时在标题行展示（null 不显示）
  final int? totalCount;

  /// 点击收起箭头
  final VoidCallback onToggleExpand;

  final ValueChanged<SearchTag> onRemoveTag;
  final VoidCallback? onClearKeyword;
  final VoidCallback onReset;

  static const int _maxRows = 2;
  static const double _rowSpacing = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasSelection =
        selectedTags.isNotEmpty || (keyword?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '筛选内容',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF3C4046),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hasSelection
                    ? '已选 ${selectedTags.length + (keyword?.isNotEmpty ?? false ? 1 : 0)}'
                    : (totalCount != null ? '共 $totalCount 条' : ''),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: hasSelection ? onReset : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    '重置',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasSelection
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 两行封顶，更多已选项在此区域内滚动
          SizedBox(
            height: _maxRows * kFilterChipHeight + (_maxRows - 1) * _rowSpacing,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: _rowSpacing,
                runSpacing: _rowSpacing,
                children: hasSelection
                    ? buildSelectedFilterChips(
                        selectedTags: selectedTags,
                        keyword: keyword,
                        onRemoveTag: onRemoveTag,
                        onClearKeyword: onClearKeyword,
                      )
                    : [
                        Text(
                          '尚未选择筛选条件，从下方卡片点击加入',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 已选 chip 的统一构建规则：关键字 chip（点击/移除即清除）+ 已选标签 chips
/// （排除态/选中态两种样式，点击或移除即移除）。
/// 收起态横条与展开态摘要共用，避免两种形态的渲染规则分叉。
List<Widget> buildSelectedFilterChips({
  required List<SearchTag> selectedTags,
  required String? keyword,
  required ValueChanged<SearchTag> onRemoveTag,
  required VoidCallback? onClearKeyword,
}) {
  final chips = <Widget>[];
  if (keyword != null && keyword.isNotEmpty) {
    chips.add(
      InlineFilterChip(
        label: '搜: $keyword',
        style: FilterChipStyle.selected,
        height: kFilterChipHeight,
        showIcon: true,
        onTap: onClearKeyword,
        onRemove: onClearKeyword,
      ),
    );
  }
  for (final tag in selectedTags) {
    chips.add(
      InlineFilterChip(
        label: tag.name,
        style: tag.isExclude
            ? FilterChipStyle.exclude
            : FilterChipStyle.selected,
        height: kFilterChipHeight,
        onTap: () => onRemoveTag(tag),
        onRemove: () => onRemoveTag(tag),
      ),
    );
  }
  return chips;
}
