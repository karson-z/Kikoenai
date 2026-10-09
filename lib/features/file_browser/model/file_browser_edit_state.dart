/// 一个浏览页的编辑模式状态。
class FileBrowserEditState {
  const FileBrowserEditState({
    this.isEditing = false,
    this.selectedKeys = const {},
  });

  static const empty = FileBrowserEditState();

  final bool isEditing;
  final Set<String> selectedKeys;

  bool allVisibleSelected(Iterable<String> visibleKeys) {
    final keys = visibleKeys.toList(growable: false);
    return keys.isNotEmpty && keys.every(selectedKeys.contains);
  }

  FileBrowserEditState copyWith({
    bool? isEditing,
    Set<String>? selectedKeys,
  }) {
    return FileBrowserEditState(
      isEditing: isEditing ?? this.isEditing,
      selectedKeys: selectedKeys ?? this.selectedKeys,
    );
  }
}
