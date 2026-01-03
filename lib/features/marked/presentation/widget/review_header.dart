import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/review_sort_type.dart';
import '../../../../core/enums/work_progress.dart';
import '../../data/model/review_query_params.dart';
import '../../data/service/review_notifier.dart';
import '../provider/review_provider.dart';

class ReviewHeader extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ReviewHeader({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(reviewParamsProvider);
    final notifier = ref.read(reviewParamsProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 顶部分段控制器
          _buildSegmentedControl(context),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center, // 垂直居中对齐
            children: [
              Row(
                mainAxisSize: MainAxisSize.min, // 紧缩宽度
                children: [
                  _buildDropdownButton(context, params, notifier),
                  const SizedBox(width: 8),
                  _buildSortButton(notifier, params),
                ],
              ),

              // 2.2 进度筛选器 (根据 selectedIndex 显示)
              if (selectedIndex == 1)
                _buildProgressSelector(context, params, notifier),
            ],
          ),
        ],
      ),
    );
  }

  /// 1. 分段控制器
  Widget _buildSegmentedControl(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              _buildTabButton(context, 0, '我的评价'),
              _buildTabButton(context, 1, '我的进度'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String text) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// 2.1 下拉菜单
  Widget _buildDropdownButton(BuildContext context, ReviewQueryParams params, ReviewParamsNotifier notifier) {
    final currentSort = ReviewSortType.fromValue(params.order);

    return PopupMenuButton<ReviewSortType>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      itemBuilder: (context) => ReviewSortType.values.map((type) {
        return PopupMenuItem<ReviewSortType>(
          value: type,
          child: Text(type.label),
        );
      }).toList(),
      onSelected: (ReviewSortType type) {
        notifier.updateFilter(order: type.value);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSort.label, // 直接使用枚举的 label
              style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 13,
                  fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  /// 2.2 排序按钮
  Widget _buildSortButton(ReviewParamsNotifier notifier, ReviewQueryParams params) {
    final isDesc = params.sort == 'desc';
    return InkWell(
      onTap: () {
        final newSort = isDesc ? 'asc' : 'desc';
        notifier.updateFilter(sort: newSort);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          isDesc ? Icons.arrow_downward : Icons.arrow_upward,
          color: Colors.grey[600],
          size: 18,
        ),
      ),
    );
  }

  /// 2.3 进度筛选器
  Widget _buildProgressSelector(BuildContext context, ReviewQueryParams params, ReviewParamsNotifier notifier) {
    final progressList = WorkProgress.values.where((e) => e != WorkProgress.unknown).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      // 内部继续使用 Wrap，防止在极小屏幕下内部撑爆
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: progressList.map((progress) {
          final isSelected = params.filter == progress.value;

          return InkWell(
            onTap: () {
              notifier.updateFilter(filter: progress.value);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                progress.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}