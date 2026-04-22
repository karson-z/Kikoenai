import '../../../album/data/model/circle.dart';
import '../../../album/data/model/tag.dart';
import '../../../album/data/model/va.dart';

class SelectorItem {
  final String id;
  final String label;
  final String type;

  SelectorItem({
    required this.id,
    required this.label,
    required this.type,
  });
}

extension CircleToSelectorItem on Circle {
  SelectorItem toSelectorItem() {
    return SelectorItem(
      id: id?.toString() ?? '',
      label: name ?? '未知',
      type: 'circle',
    );
  }
}

extension VAToSelectorItem on VA {
  SelectorItem toSelectorItem() {
    return SelectorItem(
      id: id ?? '',
      label: name ?? '未知',
      type: 'va',
    );
  }
}

extension TagToSelectorItem on Tag {
  SelectorItem toSelectorItem() {
    return SelectorItem(
      id: id?.toString() ?? '',
      label: name ?? '未知',
      type: 'tag',
    );
  }
}