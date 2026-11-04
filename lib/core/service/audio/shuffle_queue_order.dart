import 'dart:math';

/// A shuffled sequence of queue item IDs and a cursor into that sequence.
class ShuffleQueueOrder {
  ShuffleQueueOrder({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<String> _items = [];
  int _cursor = -1;

  int get cursor => _cursor;
  bool get hasNext => _cursor + 1 < _items.length;
  List<String> get items => List.unmodifiable(_items);

  void reset(
    List<String> queueIds, {
    required String? currentId,
    Object? snapshot,
  }) {
    _items.clear();
    _cursor = -1;
    if (snapshot != null && _restore(snapshot, queueIds, currentId)) return;

    if (currentId != null && queueIds.contains(currentId)) {
      _items.add(currentId);
      _cursor = 0;
    }
    final remaining = queueIds.where((id) => id != currentId).toList()
      ..shuffle(_random);
    _items.addAll(remaining);
  }

  String? next({required List<String> queueIds, required bool repeat}) {
    if (_cursor + 1 < _items.length) return _items[++_cursor];
    if (!repeat || queueIds.isEmpty) return null;

    final round = List<String>.of(queueIds)..shuffle(_random);
    final currentId = _cursor < 0 ? null : _items[_cursor];
    if (round.length > 1 && round.first == currentId) {
      final swapIndex = 1 + _random.nextInt(round.length - 1);
      final first = round.first;
      round[0] = round[swapIndex];
      round[swapIndex] = first;
    }
    _items.addAll(round);
    _cursor++;
    _trimHistory();
    return _items[_cursor];
  }

  String? previous() {
    if (_cursor <= 0) return null;
    return _items[--_cursor];
  }

  /// Select manually, keep prior history, and shuffle the unplayed queue items.
  void select(String id, List<String> queueIds) {
    if (!queueIds.contains(id)) return;
    final played = _items.take(_cursor + 1).toSet();
    final pending = _items
        .skip(_cursor + 1)
        .where(
          (item) =>
              queueIds.contains(item) && item != id && !played.contains(item),
        )
        .toList();
    final known = {...played, id, ...pending};
    final newItems = queueIds.where((item) => !known.contains(item)).toList()
      ..shuffle(_random);

    if (_cursor + 1 < _items.length) {
      _items.removeRange(_cursor + 1, _items.length);
    }
    _items.add(id);
    _cursor = _items.length - 1;
    _items.addAll(pending);
    _items.addAll(newItems);
    _trimHistory();
  }

  void addPending(Iterable<String> ids) {
    final additions = ids.toList()..shuffle(_random);
    _items.insertAll(_cursor + 1, additions);
  }

  void remove(String id) {
    final removedBeforeCursor = _items
        .take(_cursor + 1)
        .where((item) => item == id)
        .length;
    _items.removeWhere((item) => item == id);
    _cursor = max(-1, _cursor - removedBeforeCursor);
  }

  Map<String, Object> toSnapshot(List<String> queueIds) => {
    'queueIds': List<String>.of(queueIds),
    'items': List<String>.of(_items),
    'cursor': _cursor,
  };

  bool _restore(Object value, List<String> queueIds, String? currentId) {
    if (value is! Map ||
        value['queueIds'] is! List ||
        value['items'] is! List) {
      return false;
    }
    final savedQueue = (value['queueIds'] as List).whereType<String>().toList();
    final items = (value['items'] as List).whereType<String>().toList();
    final cursor = value['cursor'];
    if (cursor is! int ||
        savedQueue.length != queueIds.length ||
        savedQueue.toSet().length != queueIds.length ||
        !savedQueue.toSet().containsAll(queueIds) ||
        items.isEmpty ||
        cursor < 0 ||
        cursor >= items.length ||
        items.any((id) => !queueIds.contains(id)) ||
        (currentId != null && items[cursor] != currentId)) {
      return false;
    }
    _items.addAll(items);
    _cursor = cursor;
    return true;
  }

  void _trimHistory() {
    const maxPlayedHistory = 100;
    if (_cursor <= maxPlayedHistory) return;
    final count = _cursor - maxPlayedHistory;
    _items.removeRange(0, count);
    _cursor -= count;
  }
}
