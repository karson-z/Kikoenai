import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/features/album/presentation/viewmodel/provider/work_provider.dart';

import '../../enums/sort_options.dart';

class CollapsibleTabBar extends ConsumerWidget {
  final ValueNotifier<double> collapsePercentNotifier;
  final List<String> filters;
  final void Function(int index) onTap;

  const CollapsibleTabBar({
    super.key,
    required this.collapsePercentNotifier,
    required this.filters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = DefaultTabController.of(context);
    final workState = ref.watch(worksNotifierProvider);
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
          _buildAnimatedSortIcon(workState.value?.sortDirection, () {
            final sortDirection = workState.value?.sortDirection;
            if (sortDirection == null) return;
            if (sortDirection == SortDirection.asc) {
              ref.read(worksNotifierProvider.notifier).changeSortState(sortDec:SortDirection.desc);
            } else {
              ref.read(worksNotifierProvider.notifier).changeSortState(sortDec:SortDirection.asc);
            }
          }),
          const SizedBox(width: 8),
          _buildAnimatedSearch(),
        ],
      ),
    );
  }
  Widget _buildAnimatedSortIcon(
      SortDirection? direction,
      void Function() onTap,
      ) {
    // 移除了 AnimatedBuilder、Opacity 和 Transform
    // 现在图标会固定显示，不会随折叠进度消失或移动
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 200),
        turns: direction == SortDirection.asc ? 0 : 0.5,
        child: const Icon(
          Icons.arrow_upward,
          size: 22,
        ),
      ),
    );
  }
  Widget _buildAnimatedSearch() {
    return AnimatedBuilder(
      animation: collapsePercentNotifier,
      builder: (_, __) {
        final p = collapsePercentNotifier.value;
        if (p == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset((1 - p) * 48 * 0.3, 0),
            child: const Icon(Icons.search
              , size: 22,
            ),
          ),
        );
      },
    );
  }
}
