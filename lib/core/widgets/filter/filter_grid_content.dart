import 'package:flutter/material.dart';

import '../../model/search_tag.dart';
import '../../../features/category/data/model/selector_item.dart';

class TagGridContent extends StatelessWidget {
  final List<SelectorItem> items;
  final List<SearchTag> selectedTags;
  final TextEditingController searchController;
  final ValueChanged<SelectorItem> onItemToggled;
  final ValueChanged<String> onSearchChanged;

  const TagGridContent({
    super.key,
    required this.items,
    required this.selectedTags,
    required this.searchController,
    required this.onItemToggled,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: '搜索...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(bottom: 12.0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final tagIndex = selectedTags.indexWhere((t) => t.name == item.label);
                final SearchTag? currentTagState = tagIndex != -1 ? selectedTags[tagIndex] : null;
                // 判断状态
                final bool isIncluded = currentTagState != null && !currentTagState.isExclude;
                final bool isExcluded = currentTagState != null && currentTagState.isExclude;

                // 根据状态设置样式
                Color borderColor = Colors.transparent;
                Color textColor = const Color(0xFF4B5563);
                TextDecoration decoration = TextDecoration.none;

                if (isIncluded) {
                  borderColor = Theme.of(context).colorScheme.primary;
                  textColor = Theme.of(context).colorScheme.primary;
                } else if (isExcluded) {
                  borderColor = const Color(0xFFFECACA); // 红色边框
                  textColor = Colors.red;
                  decoration = TextDecoration.lineThrough; // 排除项增加删除线，视觉更直观
                }

                return InkWell(
                  onTap: () => onItemToggled(item),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: currentTagState != null ? FontWeight.w500 : FontWeight.normal,
                        decoration: decoration,
                        decorationColor: Colors.red, // 删除线颜色
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}