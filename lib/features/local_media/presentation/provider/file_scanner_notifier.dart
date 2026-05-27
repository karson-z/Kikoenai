import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../data/model/file_scanner_state.dart';
import 'file_path_notifier.dart';

final fileScannerProvider =
    NotifierProvider.autoDispose<FileScannerNotifier, FileBrowserState>(
      FileScannerNotifier.new,
    );

class FileScannerNotifier extends Notifier<FileBrowserState> {
  late FileScannerService _service;
  StreamSubscription? _resultSub;
  FileNodeLibraryIndex? _libraryIndex;
  FileScannerResultPhase? _lastResultPhase;

  bool get didLastResultCompleteSync =>
      _lastResultPhase == FileScannerResultPhase.syncCompleted;

  @override
  FileBrowserState build() {
    _service = FileScannerService.instance;
    ref.onDispose(_cleanupService);
    _initializeService();
    final targetsNotifier = ref.read(scanTargetsProvider.notifier);
    final ScanTarget? activeTarget = targetsNotifier.getActiveTarget();
    if (activeTarget == null) {
      return const FileBrowserState(
        rootPath: '',
        currentFolderPath: null,
        isHome: true,
      );
    }
    Future.microtask(() => startScan(activeTarget));
    final String initialPath = activeTarget.path;
    final ScanMode currentScanMode = activeTarget.scanMode;
    return FileBrowserState(
      scanMode: currentScanMode,
      rootPath: initialPath,
      currentFolderPath: initialPath,
      isHome: true,
    );
  }

  /// 内部初始化方法
  void _initializeService() {
    _resultSub?.cancel();
    _resultSub = _service.result.listen(
      (batch) {
        _lastResultPhase = batch.phase;
        _libraryIndex = FileNodeLibraryIndex(
          flatNodes: batch.flatNodes,
          rootPath: batch.rootPath,
        );
        if (state.currentFolderPath != null &&
            state.currentFolderPath != batch.rootPath) {
          _libraryIndex!.stepIn(NodeFolder(state.currentFolderPath!));
        }
        final isScanning = switch (batch.phase) {
          FileScannerResultPhase.cacheLoaded => true,
          FileScannerResultPhase.syncCompleted ||
          FileScannerResultPhase.syncSkipped => false,
          FileScannerResultPhase.statusUpdated => state.isScanning,
        };

        _updateStateFromIndex(isScanning: isScanning);
      },
      onError: (e) {
        state = state.copyWith(isScanning: false);
      },
    );
  }

  /// 开始/切换扫描路径（用户在路径管理弹窗里选中了某一条路径）
  Future<void> startScan(
    ScanTarget scanTarget, {
    bool forceSync = false,
  }) async {
    try {
      final didSync = await _service.startScan(
        scanTarget,
        forceSync: forceSync,
      );
      if (didSync) {
        await ref
            .read(scanTargetsProvider.notifier)
            .updateScanTime(path: scanTarget.path, mode: scanTarget.scanMode);
      }
    } catch (e) {
      debugPrint('FileScannerNotifier: 扫描失败: $e');
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> refreshCurrentTarget() async {
    final activeTarget = ref
        .read(scanTargetsProvider.notifier)
        .getActiveTarget();
    if (activeTarget == null) return;

    state = state.copyWith(isScanning: true);
    await startScan(activeTarget, forceSync: true);
  }

  /// 进入某个子文件夹
  void stepIn(NodeFolder folder) {
    if (_libraryIndex == null) return;
    _libraryIndex!.stepIn(folder);
    debugPrint('FileScannerNotifier: 进入子文件夹: ${folder.normalized}');
    _updateStateFromIndex();
  }

  /// 返回上一层目录
  void stepOut() {
    if (_libraryIndex == null) return;
    _libraryIndex!.stepOut();
    _updateStateFromIndex();
  }

  /// 面包屑导航栏点击跳转
  void jumpToPath(String targetFolderPath) {
    if (_libraryIndex == null) return;

    // 调用上面刚写好的内部安全跳转
    _libraryIndex!.jumpTo(targetFolderPath);

    // 刷新 UI 视图切片状态
    _updateStateFromIndex();
  }

  /// 回到当前扫描目标的根目录
  void goHome() {
    if (_libraryIndex == null) return;
    _libraryIndex!.goHome();
    _updateStateFromIndex();
  }

  /// 获取当前扫描根目录下所有待解析作品。
  ///
  /// 返回值按 workId 去重，每个作品只保留第一个命中的文件节点作为解析任务入口。
  List<FileNode> getPendingWorkNodesInActiveRoot() {
    if (_libraryIndex == null) return const [];

    final seenWorkIds = <int>{};
    final pendingNodes = <FileNode>[];
    final files = _libraryIndex!.getFilesInFolder(
      _libraryIndex!.rootFolder,
      recursive: true,
    );

    for (final node in files) {
      final workId = node.workId;
      if (workId == null || node.nodeStatus != NodeStatus.pending) continue;

      if (seenWorkIds.add(workId)) {
        pendingNodes.add(node);
      }
    }

    return pendingNodes;
  }

  /// 将树的单层节点投影，高效率、无嵌套地转换并同步为当前的 UI 视图切片状态
  void _updateStateFromIndex({bool? isScanning}) {
    if (_libraryIndex == null) return;

    state = state.copyWith(
      rootPath: _libraryIndex!.rootPath,
      currentFolderPath:
          _libraryIndex!.currentFolder?.normalized ?? _libraryIndex!.rootPath,
      children: _libraryIndex!.currentChildren, // 只提取当前目录下的直接子文件夹与文件项
      isHome: _libraryIndex!.isHome,
      isScanning: isScanning ?? state.isScanning,
    );
  }

  /// 当用户在路径管理弹窗里选中了某一条新路径（或者自动向前补位切换路径）时调用
  Future<void> changeActiveTarget(ScanTarget scanTarget) async {
    _libraryIndex = null;

    // 状态完全由传入的对象全权决定，瞬间刷新 UI 视图进入扫描加载状态
    state = FileBrowserState(
      scanMode: scanTarget.scanMode,
      rootPath: scanTarget.path,
      currentFolderPath: scanTarget.path,
      children: [],
      isScanning: true,
      isHome: true,
    );
    startScan(scanTarget);
  }

  /// 当正在被查看的文件路径被删除，且该模式下已无任何路径时调用的置空方法
  void handleCurrentPathRemoved() {
    _libraryIndex = null;
    state = const FileBrowserState(
      scanMode: ScanMode.audio,
      rootPath: '',
      currentFolderPath: '',
      children: [],
      isScanning: false,
      isHome: true,
    );
  }

  void _cleanupService() {
    _resultSub?.cancel();
    _resultSub = null;
  }
}
