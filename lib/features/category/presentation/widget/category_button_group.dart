import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/features/album/data/model/circle.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
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
                    .surfaceVariant
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
class _TagRow<T> extends StatelessWidget {
  final String title;
  final List<T> data;
  final String type;
  final bool editing;
  final List<SearchTag> selected;
  final Color? activeColor;
  final Color? excludeColor;
  final TagToggleCallback onToggle;

  const _TagRow({
    required this.title,
    required this.data,
    required this.type,
    required this.editing,
    required this.selected,
    required this.onToggle,
    this.activeColor,
    this.excludeColor,
  });

  String _getTagName(T item) {
    if (item is Tag) return item.name ?? '';
    if (item is Circle) return item.name ?? '';
    if (item is VA) return item.name ?? '';
    if (item is AgeRatingEnum) return item.value;
    return item.toString();
  }

  bool _isSelected(String name) =>
      selected.any((st) => st.type == type && st.name == name);

  bool _getIsExclude(String name) {
    final tag = selected.firstWhere(
          (st) => st.type == type && st.name == name,
      orElse: () => const SearchTag('', '', false),
    );
    return tag.isExclude;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Expanded(
            child: ScrollConfiguration(
              behavior: _DesktopHorizontalScrollBehavior(),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = data[index];
                  final tagName = _getTagName(item);
                  final isSelected = _isSelected(tagName);
                  final isExclude = _getIsExclude(tagName);

                  return EditableCheckButton(
                    editing: editing,
                    label: tagName,
                    isExclude: isExclude,
                    selected: isSelected,
                    activeColor: activeColor,
                    excludeColor: excludeColor,
                    onTap: () => onToggle(type, tagName),
                    onChanged: editing ? (checked) => onToggle(type, tagName) : null,
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

