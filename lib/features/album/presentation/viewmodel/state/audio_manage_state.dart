

import '../../../data/model/file_node.dart';

class AudioManageState {
  final bool multiSelectMode;     // 是否处于多选模式
  final List<FileNode> selected;   // 选中的文件

  const AudioManageState({
    this.multiSelectMode = false,
    this.selected = const [],
  });

  AudioManageState copyWith({
    bool? multiSelectMode,
    List<FileNode>? selected,
  }) {
    return AudioManageState(
      multiSelectMode: multiSelectMode ?? this.multiSelectMode,
      selected: selected ?? this.selected,
    );
  }
}
