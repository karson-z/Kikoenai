import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/sort_options.dart';

import '../../../features/album/presentation/viewmodel/provider/work_provider.dart';

class CollapsibleTabBar extends StatelessWidget {
  final ValueNotifier<double>? collapsePercentNotifier;
  final List<String> filters;
  final void Function(int index) onTap;

  // ---- 新增：由外部控制排序方向和点击事件 ----
  final SortDirection? sortDirection;
  final VoidCallback onSortTap;

  const CollapsibleTabBar({
    super.key,
    this.collapsePercentNotifier,
    required this.filters,
    required this.onTap,
    required this.sortDirection,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);

    return Container(
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
              onTap: onTap,
              dragStartBehavior: DragStartBehavior.down,
              tabs: filters.map((f) => Tab(text: f)).toList(),
            ),
          ),

          // 排序图标交给外部控制
          _buildAnimatedSortIcon(sortDirection, onSortTap),

          const SizedBox(width: 8),

          _buildSearchIcon(),
        ],
      ),
    );
  }

  Widget _buildSearchIcon() {
    final notifier = collapsePercentNotifier;

    if (notifier == null) {
      // 不需要折叠 → 不显示搜索图标
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: notifier,
      builder: (_, __) {
        final p = notifier.value;
        if (p == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset((1 - p) * 48 * 0.3, 0),
            child: const Icon(Icons.search, size: 22),
          ),
        );
      },
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
        child: const Icon(Icons.arrow_upward, size: 22),
      ),
    );
  }
}
