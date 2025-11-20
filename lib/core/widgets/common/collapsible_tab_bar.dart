import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/features/album/presentation/viewmodel/provider/work_provider.dart';

import '../../enums/sort_options.dart';

class CollapsibleTabBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);

    return Consumer(
      builder: (context, ref, _) {
        final workState = ref.watch(worksNotifierProvider);
        final workNotifier = ref.read(worksNotifierProvider.notifier);
        final sortDirection = workState.value?.sortDirection;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // ⬇⬇⬇ 关键：让 TabBar 不再被撑满，从而真正左对齐
              Flexible(
                fit: FlexFit.loose,
                child: TabBar(
                  controller: controller,
                  isScrollable: true,
                  labelPadding: EdgeInsets.symmetric(horizontal: 10),
                  indicatorPadding: EdgeInsets.zero,
                  onTap: onTap,
                  tabs: filters.map((f) => Tab(text: f)).toList(),
                ),
              ),
              _buildAnimatedSortIcon(
                sortDirection,
                    () {
                  final newDir = sortDirection == SortDirection.asc
                      ? SortDirection.desc
                      : SortDirection.asc;
                  workNotifier.changeSortDirection(newDir);
                },
              ),
              SizedBox(width: 10),
              _buildAnimatedSearch(),
            ],
          ),
        );
      },
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
            child: const Icon(Icons.search),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSortIcon(
      SortDirection? direction,
      void Function() onTap,
      ) {
    return AnimatedBuilder(
      animation: collapsePercentNotifier,
      builder: (_, __) {
        final p = collapsePercentNotifier.value;
        if (p == 0) return const SizedBox.shrink();

        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset((1 - p) * -48 * 0.3, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: direction == SortDirection.asc ? 0 : 0.5,
                child: const Icon(
                  Icons.arrow_upward,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
