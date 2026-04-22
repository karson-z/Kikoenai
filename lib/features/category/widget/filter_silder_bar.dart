import 'package:flutter/material.dart';
enum CategoryType {
  tag,
  group,
  va,
  special,
}

extension CategoryTypeExtension on CategoryType {
  String get label {
    switch (this) {
      case CategoryType.tag:
        return '标签';
      case CategoryType.group:
        return '社团';
      case CategoryType.va:
        return '声优';
      case CategoryType.special:
        return '特殊';
    }
  }
}
class SidebarCategoryList extends StatelessWidget {
  final List<CategoryType> categories;
  final CategoryType? activeCategory;
  final ValueChanged<CategoryType> onCategorySelected;

  const SidebarCategoryList({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      color: const Color(0xFFF9FAFB),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = activeCategory == category;

          return InkWell(
            onTap: () => onCategorySelected(category),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                border: Border(
                  left: BorderSide(
                      color: isActive ? Colors.blue : Colors.transparent,
                      width: 4
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? Colors.blue : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}