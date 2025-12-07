import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/features/album/data/model/circle.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../data/model/search_tag.dart';
import 'category_check_button.dart';

typedef SearchTagChanged = ValueChanged<List<SearchTag>>;
typedef TagToggleCallback = void Function(String type, String name);


class EditableCheckGroup extends ConsumerWidget {
  final List<Tag> tags;
  final List<Circle> circles;
  final List<VA> vas;
  final List<AgeRatingEnum> age;
  final int? count;
  final Color? activeColor;
  final Color? excludeColor;

  const EditableCheckGroup({
    super.key,
    required this.tags,
    required this.age,
    required this.circles,
    required this.vas,
    this.count,
    this.activeColor,
    this.excludeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(categoryUiProvider);
    final uiNotifier = ref.read(categoryUiProvider.notifier);

    void handleToggle(String type, String name) {
      uiNotifier.toggleTag(type, name,refreshData: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        // ---------------- 选中标签栏 ----------------
        SizedBox(
          height: 28,
          child: Row(
            children: [
              Chip(
                label: Text(
                  '筛选结果共：$count 条',
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScrollConfiguration(
                  behavior: _DesktopHorizontalScrollBehavior(),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: ui.selected.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tag = ui.selected[index];
                      return Chip(
                        label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => uiNotifier.removeTag(tag.type, tag.name, refreshData: true),
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(ui.subtitleFilter == 1 ? Icons.closed_caption : Icons.closed_caption_disabled, size: 18),
                onPressed: () => uiNotifier.setSubtitleFilter(ui.subtitleFilter == 1 ? 0 : 1,refreshData: true),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(ui.editing ? Icons.check : Icons.edit, size: 18),
                onPressed: () => uiNotifier.toggleEditing(refreshData: ui.editing),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ---------------- 标签选择行 ----------------
        _TagRow<AgeRatingEnum>(
          title: '年龄分级：',
          data: age,
          type: 'age',
          editing: ui.editing,
          selected: ui.selected,
          activeColor: activeColor,
          excludeColor: excludeColor,
          onToggle: handleToggle,
        ),
        _TagRow<Tag>(
          title: '标签：',
          data: tags,
          type: 'tag',
          editing: ui.editing,
          selected: ui.selected,
          activeColor: activeColor,
          excludeColor: excludeColor,
          onToggle: handleToggle,
        ),
        _TagRow<VA>(
          title: '作者：',
          data: vas,
          type: 'va',
          editing: ui.editing,
          selected: ui.selected,
          activeColor: activeColor,
          excludeColor: excludeColor,
          onToggle: handleToggle,
        ),
        _TagRow<Circle>(
          title: '社团：',
          data: circles,
          type: 'circle',
          editing: ui.editing,
          selected: ui.selected,
          activeColor: activeColor,
          excludeColor: excludeColor,
          onToggle: handleToggle,
        ),
      ],
    );
  }
}

// ----------------- _TagRow -----------------
class _TagRow<T> extends StatefulWidget {
  final String title;
  final List<T> data;
  final String type;
  final bool editing;
  final List<SearchTag> selected;
  final Color? activeColor;
  final Color? excludeColor;
  final TagToggleCallback onToggle;

  const _TagRow({
    super.key,
    required this.title,
    required this.data,
    required this.type,
    required this.editing,
    required this.selected,
    required this.onToggle,
    this.activeColor,
    this.excludeColor,
  });

  @override
  State<_TagRow<T>> createState() => _TagRowState<T>();
}

class _TagRowState<T> extends State<_TagRow<T>> {
  // 使用 AutoScrollController
  late AutoScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, 0),
      axis: Axis.horizontal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 获取标签显示的名称
  String _getTagName(T item) {
    if (item is Tag) return item.name ?? '';
    if (item is Circle) return item.name ?? '';
    if (item is VA) return item.name ?? '';
    if (item is AgeRatingEnum) return item.value;
    return item.toString();
  }

  bool _isSelected(String name) =>
      widget.selected.any((st) => st.type == widget.type && st.name == name);

  bool _getIsExclude(String name) {
    final tag = widget.selected.firstWhere(
          (st) => st.type == widget.type && st.name == name,
      orElse: () => const SearchTag('', '', false),
    );
    return tag.isExclude;
  }

  // 滚动到指定索引
  Future<void> _scrollToIndex(int index) async {
    await _controller.scrollToIndex(index,
        preferPosition: AutoScrollPosition.middle, // 滚动到中间
        duration: const Duration(milliseconds: 300));
  }

  @override
  void didUpdateWidget(covariant _TagRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检查是否有新的选中项，如果有，滚动到最后一个被选中的项的位置
    // 这里简单处理：只要选中列表变了，且当前类别有被选中的项，就尝试找到该项并滚动
    // 你可以根据需求优化逻辑，例如只在新增选中时滚动
    if (widget.selected != oldWidget.selected) {
      // 找到当前类别下被选中的项的索引
      final selectedIndexes = <int>[];
      for(int i=0; i<widget.data.length; i++){
        if(_isSelected(_getTagName(widget.data[i]))){
          selectedIndexes.add(i);
        }
      }

      // 如果有选中的，滚动到最新的那个（或第一个）
      // 这里的逻辑假设用户刚刚点击了一个，我们滚动到那个位置
      // 如果是初始化加载多个选中，通常滚动到第一个选中的
      if(selectedIndexes.isNotEmpty){
        // 简单的策略：如果新选中的不在旧选中的里面，说明是新点击的，滚动过去
        // 否则不乱动
        for(final index in selectedIndexes){
          final name = _getTagName(widget.data[index]);
          final wasSelected = oldWidget.selected.any((st) => st.type == widget.type && st.name == name);
          if(!wasSelected) {
            _scrollToIndex(index);
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Expanded(
            child: ScrollConfiguration(
              behavior: _DesktopHorizontalScrollBehavior(),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                controller: _controller, // 绑定控制器
                physics: const BouncingScrollPhysics(),
                itemCount: widget.data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = widget.data[index];
                  final tagName = _getTagName(item);
                  final isSelected = _isSelected(tagName);
                  final isExclude = _getIsExclude(tagName);

                  // 核心：用 AutoScrollTag 包裹 item
                  return AutoScrollTag(
                    key: ValueKey(index),
                    controller: _controller,
                    index: index,
                    child: EditableCheckButton(
                      editing: widget.editing,
                      label: tagName,
                      isExclude: isExclude,
                      selected: isSelected,
                      activeColor: widget.activeColor,
                      excludeColor: widget.excludeColor,
                      onTap: () {
                        widget.onToggle(widget.type, tagName);
                        // 点击时直接触发滚动，提升响应速度
                        _scrollToIndex(index);
                      },
                      onChanged: widget.editing
                          ? (checked) => widget.onToggle(widget.type, tagName)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- ScrollBehavior -----------------
class _DesktopHorizontalScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

