import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/model/file_node.dart';
import 'package:kikoenai/core/utils/data/other.dart';


final fileSelectionProvider = NotifierProvider.autoDispose<FileSelectionNotifier, Set<FileNode>>(() {
  return FileSelectionNotifier();
});

class FileSelectionNotifier extends Notifier<Set<FileNode>> {
  @override
  Set<FileNode> build() {
    return {}; // 初始状态为空集合
  }

  // --- Getters (计算属性) ---

  // 获取选中文件列表
  List<FileNode> get selectedList => state.toList();

  // 获取数量
  int get count => state.length;

  int get musicCount => state.where((node) => node.isAudio).length;


  // 获取总大小字符串
  String get totalSizeStr {
    int total = 0;
    for (var node in state) {
      total += (node.size ?? 0);
    }
    return OtherUtil.formatBytes(total);
  }
  /// 获取整个根列表的选中状态
  /// true: 全选, false: 全不选, null: 半选
  bool? getRootState(List<FileNode> roots) {
    // 1. 获取根列表下的所有文件
    final allLeaves = _getAllLeavesFromList(roots);

    if (allLeaves.isEmpty) return false;

    // 2. 计算已选中的数量
    int selectedCount = 0;
    for (var leaf in allLeaves) {
      if (state.contains(leaf)) {
        selectedCount++;
      }
    }

    // 3. 判断状态
    if (selectedCount == 0) return false;
    if (selectedCount == allLeaves.length) return true;
    return null;
  }
  // --- Actions (操作方法) ---
  void toggleSelectAll(List<FileNode> roots) {
    final currentState = getRootState(roots);
    final bool shouldSelect = (currentState != true); // 只要不是全选，点击就变全选

    final allLeaves = _getAllLeavesFromList(roots);

    final newState = Set<FileNode>.from(state);

    if (shouldSelect) {
      newState.addAll(allLeaves);
    } else {
      newState.removeAll(allLeaves);
    }

    state = newState;
  }

  /// 获取节点的勾选状态 (全选/半选/不选)
  /// 返回 true: 全选, false: 全不选, null: 半选
  bool? getNodeState(FileNode node) {
    // 1. 如果是文件，直接看 state(Set) 里有没有
    if (!node.isFolder) {
      return state.contains(node);
    }

    // 2. 如果是文件夹，计算子孙文件
    final allLeaves = _getAllLeafNodes(node);
    if (allLeaves.isEmpty) return false;

    int selectedCount = 0;
    for (var leaf in allLeaves) {
      if (state.contains(leaf)) {
        selectedCount++;
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == allLeaves.length) return true;
    return null; // 半选
  }

  /// 切换节点状态
  void toggleNode(FileNode node) {
    final currentState = getNodeState(node);
    final bool shouldSelect = (currentState != true); // 不是全选，就变全选

    final allLeaves = _getAllLeafNodes(node);

    //不可变数据更新
    final newState = Set<FileNode>.from(state);

    if (shouldSelect) {
      newState.addAll(allLeaves);
    } else {
      newState.removeAll(allLeaves);
    }

    state = newState; // 赋值新 Set 触发 UI 刷新
  }
  /// 获取文件列表下的所有叶子节点
  List<FileNode> _getAllLeavesFromList(List<FileNode> nodes) {
    List<FileNode> leaves = [];
    for (var node in nodes) {
      leaves.addAll(_getAllLeafNodes(node));
    }
    return leaves;
  }
  /// 递归查找所有子文件 (私有工具方法)
  List<FileNode> _getAllLeafNodes(FileNode node) {
    List<FileNode> leaves = [];
    if (node.isFolder) {
      if (node.children != null) {
        for (var child in node.children!) {
          leaves.addAll(_getAllLeafNodes(child));
        }
      }
    } else {
      leaves.add(node);
    }
    return leaves;
  }
}

final fileBrowserProvider = NotifierProvider.autoDispose.family<FileBrowserNotifier, List<FileNode>, String>(FileBrowserNotifier.new);

class FileBrowserNotifier extends Notifier<List<FileNode>> {
  final String workId;
  FileBrowserNotifier(this.workId);
  @override
  List<FileNode> build() {
    return [];
  }

  // --- Actions ---
  /// 进入文件夹
  void enterFolder(FileNode folder) {
    // 状态不可变更新：创建新列表并添加
    state = [...state, folder];
  }

  /// 返回上一级
  void goBack() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  /// 面包屑跳转 (点击头部导航)
  /// index = -1 代表根目录
  void jumpToBreadcrumbIndex(int index) {
    if (index == -1) {
      state = [];
    } else {
      // 保留 0 到 index 的路径
      state = state.sublist(0, index + 1);
    }
  }

  /// 计算当前应该显示的节点列表
  /// 需要传入 rootNodes，因为当面包屑为空时，需要显示根节点
  List<FileNode> getCurrentNodes(List<FileNode> rootNodes) {
    if (state.isEmpty) {
      return rootNodes;
    }
    return state.last.children ?? [];
  }
}