import 'dart:math' as math;

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

  /// 搜索框展开态：聚焦后向左扩展，Tab 区只保留当前激活维度。
  bool _isSearchExpanded = false;

  /// 收起态搜索框宽度。
  static const double _collapsedSearchWidth = 115;

  /// 展开动画时长。
  static const Duration _expandDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    final bool expanded = _searchFocusNode.hasFocus;
    if (expanded == _isSearchExpanded) return;
    setState(() => _isSearchExpanded = expanded);
  }

  @override
  void didUpdateWidget(covariant FilterOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换 Tab 时同步清空搜索框（notifier 已清 localSearchKeyword）
    if (oldWidget.activeType != widget.activeType) {
      _searchController.clear();
      // 「特殊」维度没有搜索框，切过去时收起展开态，避免下次回来状态错乱
      if (widget.activeType == CategoryType.special && _isSearchExpanded) {
        _searchFocusNode.unfocus();
        _isSearchExpanded = false;
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 量出单个 Tab 的固有宽度（文字与指示条取较宽者），
  /// 供展开态为其预留位置、把剩余宽度让给搜索框（即向左侧展开）。
  double _measureTabWidth(BuildContext context, CategoryType type) {
    final style =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final textPainter = TextPainter(
      text: TextSpan(text: type.label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // Tab 内容 = max(文字宽, 指示条 16)；留 4px 余量避免边缘裁切
    return math.max(textPainter.width, 16) + 4;
  }

  bool _isSelected(String label) {
    return widget.selectedTags.any(
      (t) =>
          t.type == widget.activeType.name && t.name == label && !t.isExclude,
    );
  }

  bool _isExcluded(String label) {
    return widget.selectedTags.any(
      (t) => t.type == widget.activeType.name && t.name == label && t.isExclude,
    );
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
    // 展开态：Tab 区只留当前激活维度，其余宽度让给搜索框（视觉上向左扩展）
    final bool expanded = _isSearchExpanded && !isSpecial;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 展开后搜索框吃掉激活 Tab 之外的全部宽度；窄屏兜底不低于收起宽度
          final double expandedSearchWidth =
              (constraints.maxWidth -
                      _measureTabWidth(context, widget.activeType) -
                      10)
                  .clamp(_collapsedSearchWidth, constraints.maxWidth);

          return Row(
            children: [
              Expanded(
                child: expanded
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTab(context, widget.activeType),
                      )
                    : SingleChildScrollView(
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
                AnimatedContainer(
                  duration: _expandDuration,
                  curve: Curves.easeOutCubic,
                  width: expanded ? expandedSearchWidth : _collapsedSearchWidth,
                  child: GlobalSearchInput(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: '搜索${widget.activeType.label}',
                    onChanged: widget.onSearchChanged,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    borderRadius: 24,
                    iconSize: 16,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
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
                color: active ? theme.colorScheme.primary : Colors.transparent,
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
