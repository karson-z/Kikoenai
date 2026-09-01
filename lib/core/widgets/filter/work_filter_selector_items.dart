import 'package:kikoenai_core/kikoenai_core.dart';

import 'filter_silder_bar.dart';

Map<CategoryType, List<SelectorItem>> buildWorkFilterSelectorItems(
  Iterable<Work> works,
) {
  final tags = _SelectorItemBucket('tag');
  final circles = _SelectorItemBucket('circle');
  final vas = _SelectorItemBucket('va');

  for (final work in works) {
    final circle = work.circle;
    circles.add(id: circle?.id?.toString(), label: circle?.name);

    final seenTags = <String>{};
    for (final tag in work.tags ?? const <Tag>[]) {
      if (tag.name case final String name when seenTags.add(name)) {
        tags.add(id: tag.id?.toString(), label: name);
      }
    }

    final seenVas = <String>{};
    for (final va in work.vas ?? const <VA>[]) {
      if (va.name case final String name when seenVas.add(name)) {
        vas.add(id: va.id, label: name);
      }
    }
  }

  return {
    CategoryType.tag: tags.build(),
    CategoryType.circle: circles.build(),
    CategoryType.va: vas.build(),
    CategoryType.special: const <SelectorItem>[],
  };
}

class _SelectorItemBucket {
  _SelectorItemBucket(this.type);

  final String type;
  final Map<String, _SelectorItemEntry> _entries = {};

  void add({required String? id, required String? label}) {
    if (label == null || label.trim().isEmpty) return;
    final existing = _entries[label];
    if (existing != null) {
      existing.count++;
      return;
    }
    _entries[label] = _SelectorItemEntry(
      id: id?.isNotEmpty == true ? id! : label,
      label: label,
    );
  }

  List<SelectorItem> build() {
    final entries = _entries.values.toList(growable: false)
      ..sort((left, right) {
        final countOrder = right.count.compareTo(left.count);
        if (countOrder != 0) return countOrder;
        return left.label.toLowerCase().compareTo(right.label.toLowerCase());
      });
    return entries
        .map(
          (entry) => SelectorItem(id: entry.id, label: entry.label, type: type),
        )
        .toList(growable: false);
  }
}

class _SelectorItemEntry {
  _SelectorItemEntry({required this.id, required this.label});

  final String id;
  final String label;
  int count = 1;
}
