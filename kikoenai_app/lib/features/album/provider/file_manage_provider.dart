import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../../core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';


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


  // ============================================================
  // Index-aware 视图：folder 节点由 [FileNodeLibraryIndex] 提供，
  // 其 `children` 字段为 null，因此需要借助 index 拿子文件。
  //
  // 选中规则：
  //   - 选文件 → 选单文件
  //   - 选 folder → 选中该 folder 子树下所有递归文件（含子文件夹内的文件）
  //   - "全选"勾选框 → 选中整棵树所有文件
  //
  // 注意：folder 节点的 `node.folder` 返回的是父 folder 路径，
  // 必须用 `node.path` 才能拿到 folder 自己的路径标识。
  // ============================================================

  /// 从 folder 节点拿到它"自身"的 [NodeFolder] 标识。
  /// folder 节点的 `folderPath` 是父 folder，`path` 才是自己。
  NodeFolder? _folderSelf(FileNode node) {
    if (!node.isFolder) return null;
    final p = node.path ?? node.mediaStreamUrl;
    if (p == null || p.isEmpty) return null;
    return NodeFolder(p);
  }

  /// Index 视图下的节点勾选状态。
  bool? getNodeStateForIndex(FileNode node, FileNodeLibraryIndex index) {
    if (!node.isFolder) {
      return state.contains(node);
    }

    final self = _folderSelf(node);
    if (self == null) return false;

    // 拿该 folder 子树下所有递归文件（含子文件夹里的文件）
    final allLeaves = index.recursiveFilesOf(self);
    if (allLeaves.isEmpty) return false;

    int selectedCount = 0;
    for (final leaf in allLeaves) {
      if (state.contains(leaf)) selectedCount++;
    }

    if (selectedCount == 0) return false;
    if (selectedCount == allLeaves.length) return true;
    return null;
  }

  /// Index 视图下切换节点选中状态。
  void toggleNodeForIndex(FileNode node, FileNodeLibraryIndex index) {
    if (!node.isFolder) {
      // 单文件：直接切换
      final newState = Set<FileNode>.from(state);
      if (state.contains(node)) {
        newState.remove(node);
      } else {
        newState.add(node);
      }
      state = newState;
      return;
    }

    // folder：切换该 folder 子树下所有递归文件
    final self = _folderSelf(node);
    if (self == null) return;

    final allLeaves = index.recursiveFilesOf(self);
    if (allLeaves.isEmpty) return;

    int selectedCount = 0;
    for (final leaf in allLeaves) {
      if (state.contains(leaf)) selectedCount++;
    }

    final bool shouldSelect = selectedCount != allLeaves.length;
    final newState = Set<FileNode>.from(state);
    if (shouldSelect) {
      newState.addAll(allLeaves);
    } else {
      newState.removeAll(allLeaves);
    }
    state = newState;
  }

  /// Index 视图下整个根的选中状态（用于顶部"全选"复选框）。
  /// true: 全选, false: 全不选, null: 半选
  bool? getRootStateForIndex(FileNodeLibraryIndex index) {
    final allLeaves = <FileNode>[];
    index.walkFolders((folder, directFiles) {
      allLeaves.addAll(directFiles);
    });

    if (allLeaves.isEmpty) return false;

    int selectedCount = 0;
    for (final leaf in allLeaves) {
      if (state.contains(leaf)) selectedCount++;
    }

    if (selectedCount == 0) return false;
    if (selectedCount == allLeaves.length) return true;
    return null;
  }

  /// Index 视图下全选/取消全选当前根列表。
  void toggleSelectAllForIndex(FileNodeLibraryIndex index) {
    final allLeaves = <FileNode>[];
    index.walkFolders((folder, directFiles) {
      allLeaves.addAll(directFiles);
    });

    if (allLeaves.isEmpty) return;

    int selectedCount = 0;
    for (final leaf in allLeaves) {
      if (state.contains(leaf)) selectedCount++;
    }

    final bool shouldSelect = selectedCount != allLeaves.length;
    final newState = Set<FileNode>.from(state);
    if (shouldSelect) {
      newState.addAll(allLeaves);
    } else {
      newState.removeAll(allLeaves);
    }
    state = newState;
  }

  /// 文件列表下的所有叶子节点
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