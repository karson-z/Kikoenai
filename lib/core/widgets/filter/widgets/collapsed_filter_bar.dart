import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'filter_chip.dart';
import 'filter_summary_header.dart';

/// 收起态筛选横条：单行已选 chips 横向滚动 + 「共 N 条」+ 展开箭头，
/// 无已选时展示维度快捷入口。纯展示组件，不依赖任何 provider。
///
/// 已选 chips 与展开态摘要 [FilterSummaryHeader] 共用
/// [buildSelectedFilterChips]，保证两种形态渲染的已选内容一致。
class CollapsedFilterBar extends StatelessWidget {
  const CollapsedFilterBar({
    super.key,
    required this.selectedTags,
    required this.keyword,
    this.totalCount,
    required this.quickEntries,
    required this.onToggleExpand,
    required this.onRemoveTag,
    this.onClearKeyword,
    required this.onQuickEntryTap,
  });

  final List<SearchTag> selectedTags;

  /// 作品级搜索关键字，非空时作为第一个 chip 展示
  final String? keyword;

  /// 「共 N 条」命中计数（null 不显示）
  final int? totalCount;

  /// 无已选时展示的维度快捷入口
  final List<CategoryType> quickEntries;

  final VoidCallback onToggleExpand;
  final ValueChanged<SearchTag> onRemoveTag;
  final VoidCallback? onClearKeyword;
  final ValueChanged<CategoryType> onQuickEntryTap;

  static const double _barHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleExpand,
      child: SizedBox(
        height: _barHeight,
        child: Row(
          children: [
            Expanded(child: _buildChips()),
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

  /// 单行横向 chips（无已选时显示维度快捷入口），右缘淡出
  Widget _buildChips() {
    final selectedChips = buildSelectedFilterChips(
      selectedTags: selectedTags,
      keyword: keyword,
      onRemoveTag: onRemoveTag,
      onClearKeyword: onClearKeyword,
    );
    final chips = selectedChips.isNotEmpty
        ? selectedChips
        : quickEntries
              .map(
                (type) => InlineFilterChip(
                  label: type.label,
                  style: FilterChipStyle.ghost,
                  height: kFilterChipHeight,
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
}
