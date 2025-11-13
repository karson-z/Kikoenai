import 'package:flutter/material.dart';

class CollapsibleTabBar extends StatelessWidget {
  final ValueNotifier<double> collapsePercentNotifier;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  const CollapsibleTabBar({
    Key? key,
    required this.collapsePercentNotifier,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final theme = Theme.of(context);

    return SizedBox(
      child: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TabBar
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: filters.map((f) {
                    final selected = f == selectedFilter;
                    return GestureDetector(
                      onTap: () => onFilterChanged(f),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade700,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 搜索图标右侧显示
            AnimatedBuilder(
              animation: collapsePercentNotifier,
              builder: (_, __) {
                final collapsePercent = collapsePercentNotifier.value;
                if (collapsePercent == 0) return const SizedBox.shrink();

                final opacity = collapsePercent.clamp(0.0, 1.0);
                final offsetX = (1 - opacity) * 0.3; // 从右向左滑入

                return Transform.translate(
                  offset: Offset(offsetX * 48, 0), // 48 是图标宽度参考
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.search, color: Colors.grey.shade700),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
