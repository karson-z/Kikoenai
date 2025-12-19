import 'package:kikoenai/core/model/app_media_item.dart';
import '../../../album/data/model/file_node.dart';

// 1. 定义状态类 (Immutable State)
class FileScannerState {
  // 修改点：从 String 变为 List<String>
  final List<String> rootPaths;
  final bool isScanning;
  final bool isAudioMode;
  final String statusMsg;
  final int totalCount;

  // 原始数据缓存
  final List<AppMediaItem> rawItems;
  // 构建好的树根节点
  final List<FileNode> treeRoot;
  // 当前导航路径栈 (面包屑)
  final List<String> pathStack;

  const FileScannerState({
    this.rootPaths = const [], // 默认为空列表
    this.isScanning = false,
    this.isAudioMode = true,
    this.statusMsg = '请添加文件夹开始扫描',
    this.totalCount = 0,
    this.rawItems = const [],
    this.treeRoot = const [],
    this.pathStack = const [],
  });

  FileScannerState copyWith({
    List<String>? rootPaths,
    bool? isScanning,
    bool? isAudioMode,
    String? statusMsg,
    int? totalCount,
    List<AppMediaItem>? rawItems,
    List<FileNode>? treeRoot,
    List<String>? pathStack,
  }) {
    return FileScannerState(
      rootPaths: rootPaths ?? this.rootPaths,
      isScanning: isScanning ?? this.isScanning,
      isAudioMode: isAudioMode ?? this.isAudioMode,
      statusMsg: statusMsg ?? this.statusMsg,
      totalCount: totalCount ?? this.totalCount,
      rawItems: rawItems ?? this.rawItems,
      treeRoot: treeRoot ?? this.treeRoot,
      pathStack: pathStack ?? this.pathStack,
    );
  }

  // 计算属性：获取当前视图应该显示的节点列表
  List<FileNode> get currentViewNodes {
    List<FileNode> currentLevel = treeRoot;

    // 如果在根目录且有多个扫描路径，这里的 treeRoot 应该是经过 Builder 处理过的顶层结构
    // (通常 Builder 会把多个路径合并成一个虚拟根或者直接列出顶层文件夹)

    for (String folderName in pathStack) {
      try {
        final node = currentLevel.firstWhere(
                (n) => n.isFolder && n.title == folderName
        );
        currentLevel = node.children ?? [];
      } catch (e) {
        return [];
      }
    }
    return currentLevel;
  }
}