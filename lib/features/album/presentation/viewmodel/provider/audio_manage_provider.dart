import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/model/file_node.dart';
import '../state/audio_manage_state.dart';

class AudioManageNotifier extends Notifier<AudioManageState> {
  @override
  AudioManageState build() => const AudioManageState();

  void toggleMultiSelect() {
    final now = state.multiSelectMode;
    if (now) {
      // 从多选退出 → 清空选中
      state = state.copyWith(
        multiSelectMode: false,
        selected: [],
      );
    } else {
      // 进入多选
      state = state.copyWith(multiSelectMode: true);
    }
  }
  void reset(){
    state = const AudioManageState();
  }
  void clearSelection() {
    state = state.copyWith(selected: []);
  }

  void select(FileNode node) {
    final newSet = [...state.selected, node];
    state = state.copyWith(selected: newSet);
  }

  void unselect(FileNode node) {
    final newSet = [...state.selected, node]..remove(node);
    state = state.copyWith(selected: newSet);
  }
}

final audioManageProvider =
NotifierProvider.autoDispose<AudioManageNotifier, AudioManageState>(() {
  return AudioManageNotifier();
});
