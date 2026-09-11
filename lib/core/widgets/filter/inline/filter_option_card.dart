import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../common/global_search_input.dart';
import '../../loading/lottie_loading.dart';
import 'filter_chip.dart';

/// 展开态下方的筛选项卡片：维度 Tab + 搜索框 + 选项网格。
/// 纯展示组件：数据与回调全部由容器注入。
class FilterOptionCard extends StatefulWidget {
  const FilterOptionCard({
    super.key,
    required this.tabs,
    required this.activeType,
    required this.items,
    required this.selectedTags,
    this.specialPanel,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onOptionTap,
    required this.onOptionLongPress,
  });

  /// Tab 顺序与数量（容器决定，可不含 special）
  final List<CategoryType> tabs;
  final CategoryType activeType;

  /// 当前 Tab 的选项（容器已按本地关键字过滤）
  final AsyncValue<List<SelectorItem>> items;
  final List<SearchTag> selectedTags;

  /// 「特殊」维度的自定义面板；null 时该 Tab 显示空态
  final Widget? specialPanel;

  final ValueChanged<CategoryType> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SelectorItem> onOptionTap;
  final ValueChanged<SelectorItem> onOptionLongPress;

  @override
  State<FilterOptionCard> createState() => _FilterOptionCardState();
}

class _FilterOptionCardState extends State<FilterOptionCard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void didUpdateWidget(covariant FilterOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换 Tab 时同步清空搜索框（notifier 已清 localSearchKeyword）
    if (oldWidget.activeType != widget.activeType) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isSelected(String label) {
    return widget.selectedTags.any((t) => t.name == label && !t.isExclude);
  }

  bool _isExcluded(String label) {
    return widget.selectedTags.any((t) => t.name == label && t.isExclude);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF212529) : Colors.white;
    final isSpecial = widget.activeType == CategoryType.special;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3138) : const Color(0xFFF0F1F3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, isSpecial),
          Expanded(child: _buildBody(context, isSpecial)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSpecial) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < widget.tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 18),
                    _buildTab(context, widget.tabs[i]),
                  ],
                ],
              ),
            ),
          ),
          if (!isSpecial) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 116,
              child: GlobalSearchInput(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: '搜索${widget.activeType.label}',
                onChanged: widget.onSearchChanged,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                borderRadius: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, CategoryType type) {
    final theme = Theme.of(context);
    final active = type == widget.activeType;
    return InkWell(
      onTap: () => widget.onTabChanged(type),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: active
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: 16,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isSpecial) {
    if (isSpecial) {
      final panel = widget.specialPanel;
      if (panel != null) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: panel,
        );
      }
      return _buildEmpty('该维度暂无可选项');
    }

    return widget.items.when(
      data: (items) {
        if (items.isEmpty) {
          final hasKeyword = _searchController.text.isNotEmpty;
          return _buildEmpty(hasKeyword ? '无匹配结果' : '暂无可选项');
        }
        return GridView.builder(
          primary: false,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            mainAxisExtent: 34,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final style = _isExcluded(item.label)
                ? FilterChipStyle.exclude
                : _isSelected(item.label)
                    ? FilterChipStyle.include
                    : null;
            return InlineFilterChip(
              label: item.label,
              style: style ?? FilterChipStyle.ghost,
              expand: true,
              onTap: () => widget.onOptionTap(item),
              onLongPress: () => widget.onOptionLongPress(item),
            );
          },
        );
      },
      loading: () => const Center(
        child: LottieLoadingIndicator(size: 64, message: '加载中...'),
      ),
      error: (error, _) => Center(
        child: Text(
          '加载失败，请重试',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
