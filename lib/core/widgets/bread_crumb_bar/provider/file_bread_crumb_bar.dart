import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/model/file_node.dart';

// 面包屑状态管理 Notifier
class BreadcrumbNotifier extends Notifier<List<FileNode>> {
  @override
  List<FileNode> build() => [];

  // 进入下一级目录
  void enterFolder(FileNode node) {
    state = [...state, node];
  }

  // 返回上一级目录
  void navigateBack() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  // 跳转到指定层级 (-1 代表根目录)
  void jumpTo(int index) {
    if (index == -1) {
      state = [];
    } else {
      state = state.sublist(0, index + 1);
    }
  }
}

// 暴露给 UI 的 Provider
final breadcrumbProvider = NotifierProvider.autoDispose<BreadcrumbNotifier, List<FileNode>>(() {
  return BreadcrumbNotifier();
});