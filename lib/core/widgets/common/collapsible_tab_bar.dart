import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/enums/sort_options.dart';

class CollapsibleTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> filters;
  final SortDirection? sortDirection;
  final VoidCallback onSortTap;

  // 【新增点 1】：添加字幕状态和回调
  final bool hasSubtitles;
  final VoidCallback onSubtitleTap;

  const CollapsibleTabBar({
    super.key,
    required this.controller,
    required this.filters,
    required this.sortDirection,
    required this.onSortTap,
    // 【新增点 2】：构造函数初始化
    required this.hasSubtitles,
    required this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 根据是否选中决定颜色：选中用主色，未选中用灰色
    final subtitleColor = hasSubtitles
        ? theme.colorScheme.primary
        : theme.disabledColor; // 或者 Colors.grey

    return SizedBox(
      height: 46,
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: controller,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                dividerHeight: 0,
                dragStartBehavior: DragStartBehavior.down,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: filters.map((f) => Tab(text: f, height: 46)).toList(),
              ),
            ),

            // 【新增点 3】：字幕筛选图标
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSubtitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // 使用 AnimatedSwitcher 让图标切换有过渡效果
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    // 根据状态切换图标形状
                    hasSubtitles ? Icons.closed_caption : Icons.closed_caption_disabled,
                    // 必须加上 Key，AnimatedSwitcher 才能识别出 Widget 变了
                    key: ValueKey<bool>(hasSubtitles),
                    size: 20,
                  ),
                ),
              ),
            ),

            // 排序图标
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12), // 调整左侧间距，让两个图标紧凑一点
              child: _buildAnimatedSortIcon(sortDirection, onSortTap),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSortIcon(
      SortDirection? direction,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 200),
        turns: direction == SortDirection.asc ? 0 : 0.5,
        child: const Icon(Icons.arrow_upward, size: 20),
      ),
    );
  }
}