import 'package:flutter/material.dart';

import '../../../features/category/data/model/selector_item.dart';
import '../../model/search_tag.dart';
import '../common/global_search_input.dart';

class TagGridContent extends StatelessWidget {
  final List<SelectorItem> items;
  final List<SearchTag> selectedTags;
  final TextEditingController searchController;
  final ValueChanged<SelectorItem> onItemToggled;
  final ValueChanged<String> onSearchChanged;
  final String hintText;

  const TagGridContent({
    super.key,
    required this.items,
    required this.selectedTags,
    required this.searchController,
    required this.onItemToggled,
    required this.onSearchChanged,
    this.hintText = '搜索...',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GlobalSearchInput(
                controller: searchController,
                hintText: hintText,
                onChanged: onSearchChanged,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            Expanded(
              child: GridView.builder(
                primary: false,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

                  final bool isIncluded = currentTagState != null && !currentTagState.isExclude;
                  final bool isExcluded = currentTagState != null && currentTagState.isExclude;

                  Color borderColor = Colors.transparent;
                  Color textColor = const Color(0xFF4B5563);
                  TextDecoration decoration = TextDecoration.none;

                  if (isIncluded) {
                    borderColor = Theme.of(context).colorScheme.primary;
                    textColor = Theme.of(context).colorScheme.primary;
                  } else if (isExcluded) {
                    borderColor = const Color(0xFFFECACA);
                    textColor = Colors.red;
                    decoration = TextDecoration.lineThrough;
                  }

                  return InkWell(
                    onTap: () => onItemToggled(item),
                    borderRadius: BorderRadius.circular(4),
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
                          decorationColor: Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}