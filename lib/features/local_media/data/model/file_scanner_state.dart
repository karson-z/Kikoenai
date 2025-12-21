// data/model/file_scanner_state.dart
import 'package:kikoenai/core/model/app_media_item.dart';
import '../../../album/data/model/file_node.dart';
import '../../../../core/service/file_scanner_service.dart'; // 确保导入了 ScanMode

class FileScannerState {
  final List<String> rootPaths;
  final bool isScanning;
  final ScanMode scanMode;
  final String statusMsg;
  final int totalCount;
  final List<AppMediaItem> rawItems;
  final List<FileNode> treeRoot;
  final List<String> pathStack;

  const FileScannerState({
    this.rootPaths = const [],
    this.isScanning = false,
    this.scanMode = ScanMode.audio, // 默认为音频
    this.statusMsg = '请添加文件夹开始扫描',
    this.totalCount = 0,
    this.rawItems = const [],
    this.treeRoot = const [],
    this.pathStack = const [],
  });

  FileScannerState copyWith({
    List<String>? rootPaths,
    bool? isScanning,
    ScanMode? scanMode, // [修改]
    String? statusMsg,
    int? totalCount,
    List<AppMediaItem>? rawItems,
    List<FileNode>? treeRoot,
    List<String>? pathStack,
  }) {
    return FileScannerState(
      rootPaths: rootPaths ?? this.rootPaths,
      isScanning: isScanning ?? this.isScanning,
      scanMode: scanMode ?? this.scanMode,
      statusMsg: statusMsg ?? this.statusMsg,
      totalCount: totalCount ?? this.totalCount,
      rawItems: rawItems ?? this.rawItems,
      treeRoot: treeRoot ?? this.treeRoot,
      pathStack: pathStack ?? this.pathStack,
    );
  }

  List<FileNode> get currentViewNodes {
    List<FileNode> currentLevel = treeRoot;
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