import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_service_v2.dart';
import '../../../../core/service/file/file_scanner_worker.dart';
import '../../../../core/service/permission/permission_service.dart';
import '../../data/model/file_scanner_state_v2.dart';

final fileScannerProvider =
NotifierProvider.autoDispose<FileScannerNotifier, FileScannerState>(
  FileScannerNotifier.new,
);

class FileScannerNotifier extends Notifier<FileScannerState> {
  FileScannerService? _service;
  late final CacheService _cacheService;
  StreamSubscription? _stateSub;
  StreamSubscription? _resultSub;

  @override
  FileScannerState build() {
    _cacheService = CacheService.instance;
    ref.onDispose(_cleanupService);

    const initialMode = ScanMode.audio;
    // 延迟初始化 Service
    Future.microtask(() => _initializeService(initialMode));

    return FileScannerState(
      scanMode: initialMode,
      savedPaths: _cacheService.getScanRootPaths(mode: initialMode),
    );
  }
  void _initializeService(ScanMode mode) {
    _cleanupService();
    _service = FileScannerService(mode);

    _stateSub = _service!.stateStream.listen((workerState) {
      state = state.copyWith(status: workerState);
    });

    _resultSub = _service!.result.listen(
          (roots) {
        state = state.copyWith(
          roots: roots,
          scannedCount: _countNodes(roots),
        );
      },
      onError: (e) => state = state.copyWith(
        status: WorkerState.error,
        errorMessage: e.toString(),
      ),
    );
    final saved = _cacheService.getScanRootPaths(mode: mode);
    state = state.copyWith(savedPaths: saved);
    if (saved.isNotEmpty) {
      startScan(saved.first);
    }
  }

  Future<void> switchMode(ScanMode newMode) async {
    if (state.scanMode == newMode) return;

    state = state.copyWith(
      scanMode: newMode,
      roots: [],
      currentPath: null,
      scannedCount: 0,
      status: WorkerState.idle,
      errorMessage: null,
      savedPaths: _cacheService.getScanRootPaths(mode: newMode),
    );

    _initializeService(newMode);
  }


  Future<void> startScan(String path) async {
    if (_service == null) return;
    state = state.copyWith(
      currentPath: path,
      roots: [],
      errorMessage: null,
      scannedCount: 0,
    );
    await _service!.startScan(path);
  }

  void stopScan() {
    _service?.dispose();
    state = state.copyWith(status: WorkerState.idle);
    _initializeService(state.scanMode);
  }

  /// 添加新目录
  Future<void> addDirectory() async {
    await PermissionService.requestExternalPermissions();
    // 2. 选择文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (!state.savedPaths.contains(selectedDirectory)) {
        final newPaths = [...state.savedPaths, selectedDirectory];
        state = state.copyWith(
          savedPaths: newPaths,
        );
        await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);
        await startScan(selectedDirectory);
      } else {
        await startScan(selectedDirectory);
      }
    }
  }
  Future<void> changePath(String newPath) async {
    await startScan(newPath);
  }
  /// 移除目录
  Future<void> removeDirectory(String pathToRemove) async {
    final newPaths = state.savedPaths.where((p) => p != pathToRemove).toList();
    final isRemovingCurrent = state.currentPath == pathToRemove;
    state = state.copyWith(
      savedPaths: newPaths,
      roots: isRemovingCurrent ? [] : state.roots,
      currentPath: isRemovingCurrent ? null : state.currentPath,
      scannedCount: isRemovingCurrent ? 0 : state.scannedCount,
      status: isRemovingCurrent ? WorkerState.idle : state.status,
    );

    if (isRemovingCurrent) {
      stopScan();
    }

    await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);
  }

  /// 清空所有目录
  Future<void> clearAllDirectories() async {
    state = state.copyWith(
      savedPaths: [],
      roots: [], // 清空视图
      currentPath: null,
      scannedCount: 0,
      status: WorkerState.idle,
      errorMessage: null,
    );

    // 2. 停止服务
    stopScan();

    // 3. 持久化清理
    await _cacheService.saveScanRootPaths([], mode: state.scanMode);
  }


  void _cleanupService() {
    _stateSub?.cancel();
    _resultSub?.cancel();
    _service?.dispose();
    _service = null;
  }

  int _countNodes(List<FileNode> nodes) {
    int count = 0;
    for (var node in nodes) {
      if (!node.isFolder) count++;
      if (node.children != null) count += _countNodes(node.children!);
    }
    return count;
  }
}