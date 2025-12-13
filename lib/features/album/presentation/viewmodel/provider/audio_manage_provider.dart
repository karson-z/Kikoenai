import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/model/file_node.dart';

class AudioManageState {
  final bool multiSelectMode;
  final Set<FileNode> selected; // 使用 Set 避免重复

  const AudioManageState({
    this.multiSelectMode = false,
    this.selected = const {},
  });

  AudioManageState copyWith({
    bool? multiSelectMode,
    Set<FileNode>? selected,
  }) {
    return AudioManageState(
      multiSelectMode: multiSelectMode ?? this.multiSelectMode,
      selected: selected ?? this.selected,
    );
  }
}

// 定义 Notifier
class AudioManageNotifier extends Notifier<AudioManageState> {
  @override
  AudioManageState build() {
    return const AudioManageState();
  }

  void toggleMultiSelect() {
    state = state.copyWith(
      multiSelectMode: !state.multiSelectMode,
      selected: {}, // 退出/进入模式时清空选中
    );
  }

  void reset() {
    state = const AudioManageState();
  }

  // 修复无法取消选中的核心：必须返回一个新的 Set
  void select(FileNode node) {
    state = state.copyWith(
      selected: {...state.selected, node},
    );
  }

  void unselect(FileNode node) {
    // 过滤掉目标节点，生成新 Set
    state = state.copyWith(
      selected: state.selected.where((item) => item != node).toSet(),
    );
  }

  // 新增：全选
  void selectAll(List<FileNode> allFiles) {
    state = state.copyWith(selected: allFiles.toSet());
  }

  // 新增：取消全选
  void clearSelection() {
    state = state.copyWith(selected: {});
  }
}

final audioManageProvider = NotifierProvider<AudioManageNotifier, AudioManageState>(() {
  return AudioManageNotifier();
});