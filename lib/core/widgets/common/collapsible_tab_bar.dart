import 'package:flutter/material.dart';

class CollapsibleTabBar extends StatelessWidget {
  final double collapsePercent; // 0 -> 展开, 1 -> 完全折叠
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  const CollapsibleTabBar({
    Key? key,
    required this.collapsePercent,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final theme = Theme.of(context);
    final double iconOpacity = collapsePercent.clamp(0.0, 1.0);

    return SizedBox(
      height: 48, // 固定高度
      child: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // 搜索图标渐显
            Opacity(
              opacity: iconOpacity,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.search, color: Colors.grey.shade700),
              ),
            ),
            // TabBar
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
          ],
        ),
      ),
    );
  }
}
