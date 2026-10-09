import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/file_browser_edit_state.dart';

/// 本地媒体页的编辑状态。离开页面后自动释放。
final localFileEditProvider =
    NotifierProvider.autoDispose<FileBrowserEditNotifier, FileBrowserEditState>(
      FileBrowserEditNotifier.new,
    );

/// 网盘浏览页的编辑状态。与本地媒体页互不影响。
final cloudFileEditProvider =
    NotifierProvider.autoDispose<FileBrowserEditNotifier, FileBrowserEditState>(
      FileBrowserEditNotifier.new,
    );

class FileBrowserEditNotifier extends Notifier<FileBrowserEditState> {
  @override
  FileBrowserEditState build() => FileBrowserEditState.empty;

  void enter(String keyId) {
    state = state.copyWith(isEditing: true, selectedKeys: {keyId});
  }

  void toggle(String keyId) {
    if (!state.isEditing) return;
    final next = {...state.selectedKeys};
    next.contains(keyId) ? next.remove(keyId) : next.add(keyId);
    state = state.copyWith(selectedKeys: next);
  }

  void toggleVisibleSelection(Iterable<String> visibleKeys) {
    final keys = visibleKeys.toSet();
    if (state.allVisibleSelected(keys)) {
      state = state.copyWith(selectedKeys: const {});
      return;
    }
    state = state.copyWith(selectedKeys: keys);
  }

  /// 目录或搜索结果变化后，丢掉已经不在当前列表里的选择。
  void retainVisible(Iterable<String> visibleKeys) {
    if (!state.isEditing || state.selectedKeys.isEmpty) return;
    final visible = visibleKeys.toSet();
    final retained = state.selectedKeys.intersection(visible);
    if (retained.length == state.selectedKeys.length) return;
    state = state.copyWith(selectedKeys: retained);
  }

  void exit() {
    state = state.copyWith(isEditing: false, selectedKeys: const {});
  }
}
