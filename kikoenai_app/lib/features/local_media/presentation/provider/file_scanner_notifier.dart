import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/permission/permission_service.dart';
import 'package:kikoenai/features/file_sort/presentation/provider/file_sort_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_storage.dart';
import 'file_path_notifier.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';

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

  /// 暴露内部索引（只读用途，例如面包屑路径推导）。
  /// 调用方不应直接通过返回值变更导航状态，请使用 [stepIn]/[stepOut]/
  /// [goHome]/[jumpToPath]/[jumpToBreadcrumbIndex] 等方法以保证 UI 同步。
  FileNodeLibraryIndex? get libraryIndex => _libraryIndex;

  @override
  FileBrowserState build() {
    final sortOption = ref.watch(fileSortProvider);
    _service = FileScannerService.instance;
    ref.onDispose(_cleanupService);
    _initializeService();
    if (_libraryIndex != null) {
      _libraryIndex!.applySort(sortOption);
      _updateStateFromIndex();
    }
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
        _libraryIndex!.applySort(ref.read(fileSortProvider));
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
  ///
  /// 发起扫描前会先检查文件管理权限，未授权则请求；权限被拒则中止扫描。
  Future<void> startScan(
    ScanTarget scanTarget, {
    bool forceSync = false,
  }) async {
    // 扫描前确保已获得文件管理权限，否则无法读取本地目录
    if (!await _ensureStoragePermission()) {
      state = state.copyWith(isScanning: false);
      return;
    }

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

  /// 确保已获得文件管理权限。已授权直接返回 true；未授权则发起请求。
  Future<bool> _ensureStoragePermission() async {
    if (await PermissionService.checkStoragePermission()) return true;
    return PermissionService.requestStoragePermission();
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

  /// 在本地媒体库中打开指定音频或视频文件所在的文件夹。
  ///
  /// 会自动选择包含该文件的最长扫描根目录，并同步切换音频/视频扫描模式。
  /// 文件不是受支持的媒体类型、未被任何扫描目标收录或缓存中已不存在时返回
  /// `false`。
  bool jumpToMediaFile(String filePath) {
    final mode = FileExtensions.isAudio(filePath)
        ? ScanMode.audio
        : FileExtensions.isVideo(filePath)
        ? ScanMode.video
        : null;
    if (mode == null) return false;

    final normalizedFilePath = FileNodeLibraryIndex.normalizePath(filePath);
    final targets =
        ref
            .read(scanTargetsProvider.notifier)
            .getTargetsByMode(mode)
            .where(
              (target) => _isPathInsideRoot(normalizedFilePath, target.path),
            )
            .toList()
          ..sort((a, b) {
            final aLength = FileNodeLibraryIndex.normalizePath(a.path).length;
            final bLength = FileNodeLibraryIndex.normalizePath(b.path).length;
            return bLength.compareTo(aLength);
          });

    for (final target in targets) {
      final isCurrentTarget =
          state.scanMode == mode &&
          NodeFolder(state.rootPath).hasSamePathAs(target.path);
      final currentIndex = isCurrentTarget ? _libraryIndex : null;

      if (currentIndex != null &&
          currentIndex.jumpToFilePath(normalizedFilePath)) {
        _updateStateFromIndex();
        return true;
      }

      final cachedNodes = FileScannerStorage().getNodesByRootPath(
        mode,
        target.path,
      );
      if (cachedNodes.isEmpty) continue;

      final index = FileNodeLibraryIndex(
        flatNodes: cachedNodes,
        rootPath: target.path,
      )..applySort(ref.read(fileSortProvider));
      if (!index.jumpToFilePath(normalizedFilePath)) continue;

      unawaited(
        ref
            .read(scanTargetsProvider.notifier)
            .selectTarget(path: target.path, mode: target.scanMode),
      );
      _libraryIndex = index;
      _lastResultPhase = FileScannerResultPhase.cacheLoaded;
      _updateStateFromIndex(isScanning: false);
      return true;
    }

    return false;
  }

  bool _isPathInsideRoot(String filePath, String rootPath) {
    final normalizedFilePath = FileNodeLibraryIndex.normalizePath(
      filePath,
    ).toLowerCase();
    final normalizedRootPath = FileNodeLibraryIndex.normalizePath(
      rootPath,
    ).toLowerCase();
    return normalizedFilePath == normalizedRootPath ||
        normalizedFilePath.startsWith('$normalizedRootPath/');
  }

  /// 按面包屑层级跳转（-1 代表根目录）。
  void jumpToBreadcrumbIndex(int index) {
    if (_libraryIndex == null) return;
    _libraryIndex!.jumpToBreadcrumbIndex(index);
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
