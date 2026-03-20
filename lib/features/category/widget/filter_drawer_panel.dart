import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/widgets/loading/lottie_loading.dart';
import '../../../../../../core/enums/tag_enum.dart';
import '../../../core/model/search_tag.dart';

class FilterDrawerPanel extends StatefulWidget {
  final bool isOpen;
  final int selectedFilterIndex;
  final String localSearchKeyword;
  final List<SearchTag> selectedTags;

  final FocusNode searchFocusNode;

  final AsyncValue<List<dynamic>> tagsAsync;
  final AsyncValue<List<dynamic>> circlesAsync;
  final AsyncValue<List<dynamic>> vasAsync;

  final ValueChanged<int> onFilterIndexChanged;
  final ValueChanged<String> onLocalSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final Function(String type, String name) onToggleTag;

  final String Function(String type) getLoadingMessage;

  final WidgetBuilder specialFilterBuilder;

  const FilterDrawerPanel({
    Key? key,
    required this.isOpen,
    required this.selectedFilterIndex,
    required this.localSearchKeyword,
    required this.selectedTags,
    required this.searchFocusNode,
    required this.tagsAsync,
    required this.circlesAsync,
    required this.vasAsync,
    required this.onFilterIndexChanged,
    required this.onLocalSearchChanged,
    required this.onReset,
    required this.onApply,
    required this.onToggleTag,
    required this.getLoadingMessage,
    required this.specialFilterBuilder,
  }) : super(key: key);

  @override
  State<FilterDrawerPanel> createState() => _FilterDrawerPanelState();
}

class _FilterDrawerPanelState extends State<FilterDrawerPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.localSearchKeyword;
  }

  @override
  void didUpdateWidget(covariant FilterDrawerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.localSearchKeyword.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black45;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final primaryColor = theme.colorScheme.primary;

    final categories = ["标签", "社团", "声优", "特殊"];

    return Material(
      color: bgColor,
      elevation: 4,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: widget.isOpen ? null : 0,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 260,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      color: fillColor,
                      child: ListView.builder(
                        primary: false,
                        padding: EdgeInsets.zero,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = widget.selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () {
                              widget.searchFocusNode.unfocus();
                              widget.onFilterIndexChanged(index);
                            },
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? bgColor : Colors.transparent,
                                border: isSelected
                                    ? Border(left: BorderSide(color: primaryColor, width: 3))
                                    : null,
                              ),
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected ? primaryColor : subTextColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: bgColor,
                        child: Column(
                          children: [
                            if (widget.selectedFilterIndex != 3)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: widget.searchFocusNode,
                                    onChanged: widget.onLocalSearchChanged,
                                    style: TextStyle(fontSize: 13, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: "搜索...",
                                      hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                                      prefixIcon: Icon(Icons.search, size: 18, color: subTextColor),
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: fillColor,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18),
                                          borderSide: BorderSide.none),
                                      suffixIcon: widget.localSearchKeyword.isNotEmpty
                                          ? GestureDetector(
                                        onTap: () {
                                          widget.onLocalSearchChanged("");
                                          _searchController.clear();
                                        },
                                        child: Icon(Icons.cancel, size: 16, color: subTextColor),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _buildRightContent(
                                  index: widget.selectedFilterIndex,
                                  fillColor: fillColor,
                                  textColor: textColor,
                                  primaryColor: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(top: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onReset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subTextColor,
                          side: BorderSide(color: dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("重置"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply();
                          widget.onLocalSearchChanged("");
                          _searchController.clear();
                          widget.searchFocusNode.unfocus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("完成"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightContent({
    required int index,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    switch (index) {
      case 0:
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: widget.tagsAsync,
          type: TagType.tag.stringValue,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor,
          textColor: textColor,
          primaryColor: primaryColor,
        );
      case 1:
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: widget.circlesAsync,
          type: TagType.circle.stringValue,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor,
          textColor: textColor,
          primaryColor: primaryColor,
        );
      case 2:
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: widget.vasAsync,
          type: TagType.va.stringValue,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor,
          textColor: textColor,
          primaryColor: primaryColor,
        );
      case 3:
        return SingleChildScrollView(
          primary: false,
          child: widget.specialFilterBuilder(context),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildAsyncChipGrid<T>({
    required AsyncValue<List<T>> asyncValue,
    required String type,
    required String Function(T) labelBuilder,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return asyncValue.when(
      data: (originalList) {
        final list = originalList.where((item) {
          if (widget.localSearchKeyword.isEmpty) return true;
          final name = labelBuilder(item);
          return name.toLowerCase().contains(widget.localSearchKeyword.toLowerCase());
        }).toList();

        if (list.isEmpty) {
          return Center(
              child: Text(
                  widget.localSearchKeyword.isNotEmpty ? "未找到相关结果" : "暂无选项",
                  style: TextStyle(color: textColor.withOpacity(0.5))));
        }

        return GridView.builder(
          primary: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisExtent: 36,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = list[index];
            final name = labelBuilder(item);

            final tagIndex = widget.selectedTags.indexWhere((t) => t.type == type && t.name == name);
            final isSelected = tagIndex != -1;
            final isExclude = isSelected ? widget.selectedTags[tagIndex].isExclude : false;

            return _buildGridChip(
              label: name,
              isSelected: isSelected,
              isExclude: isExclude,
              onTap: () {
                widget.searchFocusNode.unfocus();
                widget.onToggleTag(type, name);
              },
              fillColor: fillColor,
              textColor: textColor,
              primaryColor: primaryColor,
            );
          },
        );
      },
      error: (err, stack) => const Center(child: Text("加载失败", style: TextStyle(color: Colors.red))),
      loading: () => Center(
          child: LottieLoadingIndicator(
            assetPath: 'assets/animation/sakiko.json',
            message: widget.getLoadingMessage(type),
          )),
    );
  }

  Widget _buildGridChip({
    required String label,
    required bool isSelected,
    required bool isExclude,
    required VoidCallback onTap,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    Color backgroundColor;
    Color labelColor;
    Border? border;
    const errorColor = Color(0xFFFF4D4F);

    if (!isSelected) {
      backgroundColor = fillColor;
      labelColor = textColor;
      border = null;
    } else if (isExclude) {
      backgroundColor = errorColor.withOpacity(0.1);
      labelColor = errorColor;
      border = Border.all(color: errorColor);
    } else {
      backgroundColor = primaryColor.withOpacity(0.1);
      labelColor = primaryColor;
      border = Border.all(color: primaryColor);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}