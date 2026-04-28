import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:path/path.dart' as p;
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';
import '../../../../core/service/permission/permission_service.dart';
import '../../data/model/file_scanner_state.dart';

final fileScannerProvider =
    NotifierProvider.autoDispose<FileScannerNotifier, FileScannerState>(
  FileScannerNotifier.new,
);

enum _RefreshDecision {
  none,
  delayed,
  immediate,
}

class FileScannerNotifier extends Notifier<FileScannerState> {
  static const Duration _freshTtl = Duration(minutes: 5);
  static const Duration _staleTtl = Duration(hours: 24);
  static const Duration _delayedRefresh = Duration(milliseconds: 600);

  FileScannerService? _service;
  late final CacheService _cacheService;
  late final FileScannerStorage _storage;
  StreamSubscription<WorkerState>? _stateSub;
  StreamSubscription<FileScanBatch>? _resultSub;
  Timer? _refreshTimer;

  int _scanGeneration = 0;
  int _runIdSeed = 0;
  int _activeRunId = 0;

  final p.Context _posix = p.Context(style: p.Style.posix);

  Box<dynamic> get _box => AppStorage.settingsBox;

  static const String _lastModeKey = 'scanner_last_mode';
  String _getLastPathKey(ScanMode mode) => 'scanner_last_path_${mode.name}';

  @override
  FileScannerState build() {
    _cacheService = CacheService.instance;
    _storage = FileScannerStorage();

    ref.onDispose(_disposeAll);

    final savedModeStr = _box.get(_lastModeKey) as String?;
    final initialMode = ScanMode.values.firstWhere(
      (mode) => mode.name == savedModeStr,
      orElse: () => ScanMode.audio,
    );

    final savedPaths = _cacheService.getScanRootPaths(mode: initialMode);
    final lastPath = _box.get(_getLastPathKey(initialMode)) as String?;
    final targetPath = (lastPath != null && savedPaths.contains(lastPath))
        ? lastPath
        : null;

    Future.microtask(() async {
      _createService(initialMode);
      if (targetPath != null) {
        await openPath(targetPath);
      }
    });

    return FileScannerState(
      scanMode: initialMode,
      currentPath: targetPath,
      savedPaths: savedPaths,
    );
  }

  Future<void> switchMode(ScanMode newMode) async {
    if (state.scanMode == newMode) return;

    await _box.put(_lastModeKey, newMode.name);
    await _cancelPendingWork();
    _disposeService();
    _createService(newMode);

    final savedPaths = _cacheService.getScanRootPaths(mode: newMode);
    final lastPath = _box.get(_getLastPathKey(newMode)) as String?;
    final targetPath = (lastPath != null && savedPaths.contains(lastPath))
        ? lastPath
        : null;

    state = FileScannerState(
      scanMode: newMode,
      savedPaths: savedPaths,
      currentPath: targetPath,
    );

    if (targetPath != null) {
      await openPath(targetPath);
    } else {
      _resetBreadcrumb();
    }
  }

  Future<void> openPath(String path) async {
    _ensureService(state.scanMode);

    final mode = state.scanMode;
    final generation = ++_scanGeneration;

    await _cancelPendingWork();
    _resetBreadcrumb();
    await _box.put(_getLastPathKey(mode), path);

    if (!_isContextActive(generation, mode)) return;

    state = state.copyWith(
      currentPath: path,
      errorMessage: null,
      status: WorkerState.idle,
    );

    final snapshot = await _service!.loadCached(path);
    if (!_isPathContextActive(generation, mode, path)) return;

    final meta = snapshot.meta;
    state = state.copyWith(
      currentPath: path,
      roots: snapshot.nodes,
      scannedCount: snapshot.scannedCount,
      syncStatus: _derivePassiveSyncStatus(
        meta: meta,
        hasCachedData: snapshot.hasCachedData,
      ),
      lastSuccessfulScanAt: meta?.lastSuccessfulScanAt,
      hasCachedData: snapshot.hasCachedData,
      isDirty: meta?.isDirty ?? false,
      errorMessage: null,
      status: WorkerState.idle,
    );

    final decision = _decideRefresh(
      meta: meta,
      hasCachedData: snapshot.hasCachedData,
    );
    switch (decision) {
      case _RefreshDecision.none:
        return;
      case _RefreshDecision.delayed:
        _scheduleRefresh(path, generation);
        return;
      case _RefreshDecision.immediate:
        await _runSync(path, generation: generation, markDirty: false);
        return;
    }
  }

  Future<void> refreshCurrentPath({bool force = false}) async {
    final path = state.currentPath;
    if (path == null) return;

    final generation = ++_scanGeneration;
    await _cancelPendingWork();
    await _runSync(path, generation: generation, markDirty: force);
  }

  Future<void> stopRefresh() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    await _service?.cancel();

    final path = state.currentPath;
    final meta = path == null ? null : _storage.getRootMeta(state.scanMode, path);
    final hasCachedData = _hasStableCache(path, meta);

    state = state.copyWith(
      syncStatus: _derivePassiveSyncStatus(
        meta: meta,
        hasCachedData: hasCachedData,
      ),
      lastSuccessfulScanAt: meta?.lastSuccessfulScanAt,
      hasCachedData: hasCachedData,
      isDirty: meta?.isDirty ?? state.isDirty,
      status: WorkerState.idle,
      errorMessage: null,
    );
  }

  Future<void> addDirectory() async {
    await PermissionService.requestStoragePermission();
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    final duplicatePath = state.savedPaths.firstWhere(
      (path) => _normalizePath(path) == _normalizePath(selectedDirectory),
      orElse: () => '',
    );

    if (duplicatePath.isNotEmpty) {
      await openPath(duplicatePath);
      return;
    }

    final overlap = state.savedPaths.any(
      (path) => _pathsOverlap(path, selectedDirectory),
    );
    if (overlap) {
      KikoenaiToast.warning('当前模式下不允许添加重叠的根路径');
      return;
    }

    final newPaths = [...state.savedPaths, selectedDirectory];
    state = state.copyWith(savedPaths: newPaths);
    await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);
    await openPath(selectedDirectory);
  }

  Future<void> removeDirectory(String pathToRemove) async {
    final currentMode = state.scanMode;
    final newPaths = state.savedPaths.where((path) => path != pathToRemove).toList();
    final isRemovingCurrent = state.currentPath == pathToRemove;
    final lastPathKey = _getLastPathKey(currentMode);
    final savedLastPath = _box.get(lastPathKey) as String?;

    if (isRemovingCurrent) {
      await _cancelPendingWork();
      _resetBreadcrumb();
    }

    await _cacheService.saveScanRootPaths(newPaths, mode: currentMode);
    await _storage.clearByRootPath(currentMode, pathToRemove);

    if (savedLastPath == pathToRemove) {
      await _box.delete(lastPathKey);
    }

    state = state.copyWith(
      savedPaths: newPaths,
      roots: isRemovingCurrent ? const [] : state.roots,
      currentPath: isRemovingCurrent ? null : state.currentPath,
      scannedCount: isRemovingCurrent ? 0 : state.scannedCount,
      syncStatus: isRemovingCurrent ? ScanSyncStatus.empty : state.syncStatus,
      lastSuccessfulScanAt: isRemovingCurrent ? null : state.lastSuccessfulScanAt,
      hasCachedData: isRemovingCurrent ? false : state.hasCachedData,
      isDirty: isRemovingCurrent ? false : state.isDirty,
      status: isRemovingCurrent ? WorkerState.idle : state.status,
      errorMessage: isRemovingCurrent ? null : state.errorMessage,
    );
  }

  Future<void> clearAllDirectories() async {
    final currentMode = state.scanMode;
    await _cancelPendingWork();
    _resetBreadcrumb();

    await Future.wait([
      _box.delete(_getLastPathKey(currentMode)),
      _cacheService.saveScanRootPaths([], mode: currentMode),
      _storage.clearByMode(currentMode),
    ]);

    state = state.copyWith(
      savedPaths: const [],
      roots: const [],
      currentPath: null,
      scannedCount: 0,
      syncStatus: ScanSyncStatus.empty,
      lastSuccessfulScanAt: null,
      hasCachedData: false,
      isDirty: false,
      status: WorkerState.idle,
      errorMessage: null,
    );
  }

  void _createService(ScanMode mode) {
    _disposeService();
    _service = FileScannerService(mode);

    _stateSub = _service!.stateStream.listen((workerState) {
      state = state.copyWith(status: workerState);
    });

    _resultSub = _service!.result.listen(
      (batch) {
        if (batch.runId != _activeRunId) return;
        if (batch.rootPath.isNotEmpty && batch.rootPath != state.currentPath) {
          return;
        }

        state = state.copyWith(
          roots: batch.nodes,
          scannedCount: batch.scannedCount,
          hasCachedData:
              state.hasCachedData || batch.nodes.isNotEmpty || batch.scannedCount > 0,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: WorkerState.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  void _ensureService(ScanMode mode) {
    if (_service == null) {
      _createService(mode);
    }
  }

  Future<void> _runSync(
    String path, {
    required int generation,
    required bool markDirty,
  }) async {
    final mode = state.scanMode;
    _ensureService(mode);

    if (markDirty) {
      await _storage.markRootDirty(mode, path, isDirty: true);
    }
    if (!_isPathContextActive(generation, mode, path)) return;

    _activeRunId = ++_runIdSeed;
    state = state.copyWith(
      syncStatus: ScanSyncStatus.refreshing,
      errorMessage: null,
      isDirty: markDirty || state.isDirty,
    );

    final result = await _service!.sync(path, runId: _activeRunId);
    if (!_isPathContextActive(generation, mode, path)) return;

    final meta = _storage.getRootMeta(mode, path);
    final hasCachedData = _hasStableCache(path, meta);

    switch (result.status) {
      case SyncRunStatus.success:
        state = state.copyWith(
          syncStatus: ScanSyncStatus.fresh,
          scannedCount: result.scannedCount,
          lastSuccessfulScanAt: meta?.lastSuccessfulScanAt,
          hasCachedData: true,
          isDirty: false,
          errorMessage: null,
        );
        return;
      case SyncRunStatus.cancelled:
        state = state.copyWith(
          syncStatus: _derivePassiveSyncStatus(
            meta: meta,
            hasCachedData: hasCachedData,
          ),
          scannedCount: meta?.cachedFileCount ?? state.scannedCount,
          lastSuccessfulScanAt: meta?.lastSuccessfulScanAt,
          hasCachedData: hasCachedData,
          isDirty: meta?.isDirty ?? state.isDirty,
          errorMessage: null,
          status: WorkerState.idle,
        );
        return;
      case SyncRunStatus.error:
        state = state.copyWith(
          syncStatus: hasCachedData ? ScanSyncStatus.error : ScanSyncStatus.error,
          scannedCount: meta?.cachedFileCount ?? state.scannedCount,
          lastSuccessfulScanAt: meta?.lastSuccessfulScanAt,
          hasCachedData: hasCachedData,
          isDirty: meta?.isDirty ?? state.isDirty,
          errorMessage: result.errorMessage,
        );
        return;
    }
  }

  void _scheduleRefresh(String path, int generation) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_delayedRefresh, () {
      if (!_isPathContextActive(generation, state.scanMode, path)) return;
      unawaited(
        _runSync(
          path,
          generation: generation,
          markDirty: false,
        ),
      );
    });
  }

  _RefreshDecision _decideRefresh({
    required RootScanMeta? meta,
    required bool hasCachedData,
  }) {
    if (!hasCachedData || meta?.lastSuccessfulScanAt == null) {
      return _RefreshDecision.immediate;
    }

    if (meta!.isDirty ||
        meta.lastScanStatus == RootScanStatus.error ||
        meta.lastScanStatus == RootScanStatus.cancelled) {
      return _RefreshDecision.immediate;
    }

    final age = DateTime.now().difference(meta.lastSuccessfulScanAt!);
    if (age <= _freshTtl) {
      return _RefreshDecision.none;
    }
    if (age <= _staleTtl) {
      return _RefreshDecision.delayed;
    }
    return _RefreshDecision.immediate;
  }

  ScanSyncStatus _derivePassiveSyncStatus({
    required RootScanMeta? meta,
    required bool hasCachedData,
  }) {
    if (!hasCachedData) {
      return ScanSyncStatus.empty;
    }
    if (meta?.lastScanStatus == RootScanStatus.error) {
      return ScanSyncStatus.error;
    }
    if (meta?.lastSuccessfulScanAt != null &&
        meta?.isDirty != true &&
        DateTime.now().difference(meta!.lastSuccessfulScanAt!) <= _freshTtl) {
      return ScanSyncStatus.fresh;
    }
    return ScanSyncStatus.stale;
  }

  bool _hasStableCache(String? path, RootScanMeta? meta) {
    if (path == null) return false;
    return state.roots.isNotEmpty ||
        _storage.hasRootIndex(state.scanMode, path) ||
        meta?.lastSuccessfulScanAt != null;
  }

  Future<void> _cancelPendingWork() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _service?.cancel();
  }

  bool _isContextActive(int generation, ScanMode mode) {
    return generation == _scanGeneration && state.scanMode == mode;
  }

  bool _isPathContextActive(int generation, ScanMode mode, String path) {
    return _isContextActive(generation, mode) && state.currentPath == path;
  }

  String _normalizePath(String path) {
    var normalized = _posix.normalize(path.replaceAll('\\', '/'));
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }

  bool _pathsOverlap(String a, String b) {
    final normalizedA = _normalizePath(a);
    final normalizedB = _normalizePath(b);
    if (normalizedA == normalizedB) return true;
    return _posix.isWithin(normalizedA, normalizedB) ||
        _posix.isWithin(normalizedB, normalizedA);
  }

  void _resetBreadcrumb() {
    ref.read(breadcrumbProvider(BreadCrumbBarType.local).notifier).jumpTo(-1);
  }

  void _disposeService() {
    _stateSub?.cancel();
    _stateSub = null;
    _resultSub?.cancel();
    _resultSub = null;
    _service?.dispose();
    _service = null;
  }

  void _disposeAll() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _disposeService();
  }
}
