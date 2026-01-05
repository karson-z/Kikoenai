import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../core/model/search_tag.dart';

class FilterRowPanel extends StatelessWidget {
  // --- 数据参数 ---
  final bool isFilterOpen;       // 替代 uiState.isFilterOpen
  final String? keyword;         // 替代 uiState.keyword
  final List<SearchTag> selectedTags; // 替代 uiState.selected
  final int totalCount;

  // --- 回调函数 ---
  final VoidCallback onToggleFilter; // 替代 notifier.toggleFilterDrawer()
  final VoidCallback onClearKeyword; // 替代 notifier.updateKeyword("")
  final ValueChanged<SearchTag> onRemoveTag; // 替代 notifier.removeTag(...)

  // --- 样式/控制器参数 ---
  final AutoScrollController scrollController;
  final Color bgColor;
  final Color textColor;
  final Color subTextColor;
  final Color fillColor;
  final Color primaryColor;

  const FilterRowPanel({
    Key? key,
    // 数据
    required this.isFilterOpen,
    this.keyword,
    required this.selectedTags,
    required this.totalCount,
    // 回调
    required this.onToggleFilter,
    required this.onClearKeyword,
    required this.onRemoveTag,
    // 样式
    required this.scrollController,
    required this.bgColor,
    required this.textColor,
    required this.subTextColor,
    required this.fillColor,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double rowHeight = 40.0;
    const double badgeSpaceOffset = 6.0;

    // 1. 判断是否有关键字
    final bool hasKeyword = keyword != null && keyword!.isNotEmpty;
    // 2. 计算列表总长度
    final int itemCount = selectedTags.length + (hasKeyword ? 1 : 0);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(left: 16, right: 0),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. 筛选按钮 ---
          Padding(
            padding: const EdgeInsets.only(top: badgeSpaceOffset + 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: onToggleFilter, // 调用回调
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFilterOpen ? primaryColor.withOpacity(0.1) : fillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFilterOpen ? Icons.keyboard_arrow_up : Icons.tune,
                          size: 16,
                          color: isFilterOpen ? primaryColor : textColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFilterOpen ? "收起" : "筛选",
                          style: TextStyle(
                            color: isFilterOpen ? primaryColor : textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedTags.isNotEmpty && !isFilterOpen)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                      child: Text(
                        "${selectedTags.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  )
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- 2. 选中的 Tag 列表 ---
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.85, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: rowHeight,
                child: ListView.builder(
                  clipBehavior: Clip.hardEdge,
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  padding: const EdgeInsets.fromLTRB(0, 8, 4, 4),
                  itemBuilder: (context, index) {
                    final String displayText;
                    final Color itemColor;
                    final VoidCallback onDelete;
                    final bool isKeywordItem = hasKeyword && index == 0;

                    if (isKeywordItem) {
                      displayText = "搜: $keyword";
                      itemColor = primaryColor;
                      onDelete = onClearKeyword; // 调用回调
                    } else {
                      final tagIndex = hasKeyword ? index - 1 : index;
                      final tag = selectedTags[tagIndex];
                      displayText = tag.name;
                      itemColor = tag.isExclude ? const Color(0xFFFF4D4F) : primaryColor;
                      // 调用回调，把 tag 传出去
                      onDelete = () => onRemoveTag(tag);
                    }

                    return AutoScrollTag(
                      key: ValueKey(isKeywordItem ? "keyword_special_key" : index),
                      controller: scrollController,
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: itemColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: itemColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isKeywordItem)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.search, size: 10, color: itemColor),
                                    ),
                                  Text(
                                    displayText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: itemColor,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 删除按钮
                            Positioned(
                              top: -16,
                              right: -16,
                              child: GestureDetector(
                                onTap: onDelete,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  color: Colors.transparent, // 扩大点击区域
                                  padding: const EdgeInsets.all(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      shape: BoxShape.circle,
                                      border: Border.all(color: bgColor, width: 1),
                                    ),
                                    child: const Icon(Icons.close, size: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // --- 3. 总数统计 ---
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4, top: badgeSpaceOffset + 6),
            child: Text(
              "共 $totalCount 条",
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}