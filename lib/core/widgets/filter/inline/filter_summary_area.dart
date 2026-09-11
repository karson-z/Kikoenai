import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'filter_chip.dart';

/// 筛选区摘要：
/// - 收起态：单行已选 chips 横向滚动 + 「共 N 条」+ 展开箭头
/// - 展开态：灰底两行已选 chips（Wrap，超出内部滚动）+ 重置 + 收起箭头
/// 纯展示组件，不依赖任何 provider。
class FilterSummaryArea extends StatelessWidget {
  const FilterSummaryArea({
    super.key,
    required this.isExpanded,
    required this.selectedTags,
    this.keyword,
    this.totalCount,
    required this.quickEntries,
    required this.onToggleExpand,
    required this.onRemoveTag,
    this.onClearKeyword,
    required this.onReset,
    required this.onQuickEntryTap,
  });

  final bool isExpanded;
  final List<SearchTag> selectedTags;

  /// 作品级搜索关键字，非空时作为第一个 chip 展示
  final String? keyword;
  final int? totalCount;

  /// 无已选时收起条上的维度快捷入口
  final List<CategoryType> quickEntries;

  final VoidCallback onToggleExpand;
  final ValueChanged<SearchTag> onRemoveTag;
  final VoidCallback? onClearKeyword;
  final VoidCallback onReset;
  final ValueChanged<CategoryType> onQuickEntryTap;

  static const double _barHeight = 44;
  static const int _chipHeight = 28;
  static const int _maxRows = 2;
  static const double _rowSpacing = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grayBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE9EAEC);

    if (!isExpanded) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggleExpand,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              Expanded(child: _buildCollapsibleChips(context)),
              if (totalCount != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    '共 $totalCount 条',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasSelection =
        selectedTags.isNotEmpty || (keyword?.isNotEmpty ?? false);

    return Container(
      color: grayBg,
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
            height: _maxRows * _chipHeight + (_maxRows - 1) * _rowSpacing,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: _rowSpacing,
                runSpacing: _rowSpacing,
                children: hasSelection
                    ? _buildSelectedChips(context)
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

  /// 收起态：单行横向 chips（无已选时显示维度快捷入口），右缘淡出
  Widget _buildCollapsibleChips(BuildContext context) {
    final selectedChips = _buildSelectedChips(context);
    final chips = selectedChips.isNotEmpty
        ? selectedChips
        : quickEntries
              .map(
                (type) => InlineFilterChip(
                  label: type.label,
                  style: FilterChipStyle.ghost,
                  height: _chipHeight.toDouble(),
                  onTap: () => onQuickEntryTap(type),
                ),
              )
              .toList(growable: false);

    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.85, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectedChips(BuildContext context) {
    final chips = <Widget>[];
    if (keyword != null && keyword!.isNotEmpty) {
      chips.add(
        InlineFilterChip(
          label: '搜: $keyword',
          style: FilterChipStyle.selected,
          height: _chipHeight.toDouble(),
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
          height: _chipHeight.toDouble(),
          onTap: () => onRemoveTag(tag),
          onRemove: () => onRemoveTag(tag),
        ),
      );
    }
    return chips;
  }
}
