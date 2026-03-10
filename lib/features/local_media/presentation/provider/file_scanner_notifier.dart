import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';
import '../../../../core/service/permission/permission_service.dart';
import '../../../../core/utils/scraper/scraper_controller.dart';
import '../../data/model/file_scanner_state.dart';

final fileScannerProvider =
NotifierProvider.autoDispose<FileScannerNotifier, FileScannerState>(
  FileScannerNotifier.new,
);

/// 文件扫描服务，仅作为扫描文件的入口
/// 拥有保存路径，扫描状态，扫描进度等信息
/// 管控 Worker 后台扫描的全生命周期
/// 并将扫描结果交给爬虫队列管理的provider
class FileScannerNotifier extends Notifier<FileScannerState> {
  FileScannerService? _service;
  late final CacheService _cacheService;
  StreamSubscription? _stateSub;
  StreamSubscription? _resultSub;

  Box<dynamic> get _box => AppStorage.settingsBox;

  // --- 持久化 Key 生成 ---
  static const String _lastModeKey = 'scanner_last_mode';
  String _getLastPathKey(ScanMode mode) => 'scanner_last_path_${mode.name}';

  @override
  FileScannerState build() {
    _cacheService = CacheService.instance;
    ref.onDispose(_cleanupService);

    // 1. 从 settingBox 恢复用户上次关闭 APP 时停留的模式，默认 audio
    final savedModeStr = _box.get(_lastModeKey) as String?;
    final initialMode = ScanMode.values.firstWhere(
          (e) => e.name == savedModeStr,
      orElse: () => ScanMode.audio,
    );

    final savedPaths = _cacheService.getScanRootPaths(mode: initialMode);

    // 2. 从 settingBox 恢复该模式下最后一次扫描的路径
    final lastPath = _box.get(_getLastPathKey(initialMode)) as String?;

    // 安全校验：如果这个路径后来在其他地方被删除了，就不恢复
    final targetPath = (lastPath != null && savedPaths.contains(lastPath))
        ? lastPath
        : null;

    // 3. 首次进入：如果存在合法的历史路径，则传递给底层自动恢复扫描
    Future.microtask(() => _initializeService(initialMode, targetPath: targetPath));

    return FileScannerState(
      scanMode: initialMode,
      currentPath: targetPath, // 恢复 UI 的选中状态
      savedPaths: savedPaths,
    );
  }

  /// 初始化服务
  /// [targetPath] 如果传入了具体的路径，说明是冷启动恢复，底层将自动开始扫描该路径
  void _initializeService(ScanMode mode, {String? targetPath}) {
    _cleanupService(); // 确保旧的订阅和实例被彻底释放
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

    // 如果传入了恢复路径，立即触发扫描
    if (targetPath != null) {
      startScan(targetPath);
    }
  }

  /// 切换模式 (仅切换状态并准备 Service，绝不自动扫描)
  Future<void> switchMode(ScanMode newMode) async {
    if (state.scanMode == newMode) return;

    // 记录用户当前所处的模式到 SettingBox
    await _box.put(_lastModeKey, newMode.name);

    // 1. 立即停止并清理当前模式正在进行的任何后台扫描
    _cleanupService();

    // 2. 更新 UI 状态：加载新模式的保存路径，清空当前正在扫描的路径 (currentPath) 和结果
    state = state.copyWith(
      scanMode: newMode,
      roots: [],
      currentPath: null, // 置空当前路径，等待用户手动点击列表中的路径
      scannedCount: 0,
      status: WorkerState.idle,
      errorMessage: null,
      savedPaths: _cacheService.getScanRootPaths(mode: newMode),
    );

    // 3. 预先为新模式分配好底层的 Service，强制不传入 targetPath
    _initializeService(newMode, targetPath: null);
  }

  /// 更改路径/开始扫描 (这是用户选中某个模式下某个路径时的入口)
  Future<void> changePath(String newPath) async {
    // 每次点击新路径时，复用 startScan 逻辑
    await startScan(newPath);
  }

  /// 底层执行扫描的逻辑
  Future<void> startScan(String path) async {
    // 兜底防御：如果因为某种原因 Service 被销毁了，根据当前的 scanMode 重新建一个
    if (_service == null) {
      _initializeService(state.scanMode, targetPath: null);
    }
    await _box.put(_getLastPathKey(state.scanMode), path);
    state = state.copyWith(
      currentPath: path,
      roots: [], // 清空上一个路径遗留的数据，准备迎接新数据流
      errorMessage: null,
      scannedCount: 0,
    );

    await _service?.startScan(path);
  }

  /// 停止扫描
  void stopScan() {
    _cleanupService(); // 直接清理底层的订阅和服务
    state = state.copyWith(status: WorkerState.idle);
    // 重新初始化 Service 以备下次使用
    _initializeService(state.scanMode, targetPath: null);
  }

  /// 添加新目录
  Future<void> addDirectory() async {
    await PermissionService.requestExternalPermissions();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      if (!state.savedPaths.contains(selectedDirectory)) {
        final newPaths = [...state.savedPaths, selectedDirectory];
        state = state.copyWith(savedPaths: newPaths);
        await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);
      }
      // 无论之前有没有，选中后都立即开始扫描该路径
      await startScan(selectedDirectory);
    }
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

    await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);

    if (isRemovingCurrent) {
      await _box.delete(_getLastPathKey(state.scanMode));
      stopScan(); // 停掉底层任务
    }
  }

  /// 清空所有目录
  Future<void> clearAllDirectories() async {
    stopScan(); // 先停止服务

    await _box.delete(_getLastPathKey(state.scanMode));

    state = state.copyWith(
      savedPaths: [],
      roots: [],
      currentPath: null,
      scannedCount: 0,
      status: WorkerState.idle,
      errorMessage: null,
    );

    await _cacheService.saveScanRootPaths([], mode: state.scanMode);
  }

  void _cleanupService() {
    _stateSub?.cancel();
    _stateSub = null;
    _resultSub?.cancel();
    _resultSub = null;
    _service?.dispose();
    _service = null;
  }

  /// 递归统计 (注意：如果未来性能卡顿，建议将此逻辑移交给 Worker 在 Isolate 中处理)
  int _countNodes(List<FileNode> nodes) {
    int count = 0;
    for (var node in nodes) {
      if (!node.isFolder) count++;
      if (node.children != null) count += _countNodes(node.children!);
    }
    return count;
  }
}