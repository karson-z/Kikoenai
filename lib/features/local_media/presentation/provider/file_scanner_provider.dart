import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/permission/permission_service.dart';
import '../../../../core/constants/app_file_extensions.dart';
import '../../../../core/model/app_media_item.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../data/model/file_scanner_state.dart';
import '../../data/service/tree_service.dart';

class FileScannerNotifier extends Notifier<FileScannerState> {
  StreamSubscription? _scanSubscription;
  final Map<String, StreamSubscription<FileSystemEvent>> _fileWatchers = {};

  // 便捷访问单例
  CacheService get _cacheService => CacheService.instance;

  @override
  FileScannerState build() {
    ref.onDispose(() {
      _scanSubscription?.cancel();
      for (var sub in _fileWatchers.values) {
        sub.cancel();
      }
    });

    Future.microtask(() => _initData());

    return const FileScannerState();
  }

  // --- 初始化数据 (已重构为同步读取逻辑) ---
  void _initData() {
    final currentMode = state.scanMode;

    // [重构点 1] 同步读取，移除 await
    final paths = _cacheService.getScanRootPaths(mode: currentMode);

    if (paths.isEmpty) {
      state = state.copyWith(rootPaths: [], statusMsg: "请添加文件夹");
      return;
    }

    // [重构点 2] 同步读取缓存结果
    final cachedItems = _cacheService.getCachedScanResults(mode: currentMode);

    if (cachedItems.isNotEmpty) {
      _loadFromCache(paths, cachedItems, currentMode);
    } else {
      _startScan(paths, currentMode);
    }
  }

  void _loadFromCache(List<String> paths, List<AppMediaItem> items, ScanMode mode) {
    // MediaTreeBuilder 是纯 CPU 计算，可以直接执行
    final tree = MediaTreeBuilder.build(items, paths);
    state = state.copyWith(
      rootPaths: paths,
      scanMode: mode,
      rawItems: items,
      treeRoot: tree,
      totalCount: items.length,
      statusMsg: "加载完成 (${items.length}个文件)",
    );
    _setupFileWatchers(paths);
  }

  // --- 切换模式 (已重构为同步读取逻辑) ---
  Future<void> switchMode(ScanMode newMode) async {
    if (state.scanMode == newMode) return;

    //同步读取新模式的配置
    final targetPaths = _cacheService.getScanRootPaths(mode: newMode);
    final targetItems = _cacheService.getCachedScanResults(mode: newMode);

    if (targetItems.isNotEmpty) {
      _loadFromCache(targetPaths, targetItems, newMode);
    } else {
      // 如果没有缓存，或者缓存为空，且有路径，则开始扫描
      // 注意：这里需要处理 targetPaths 为空的情况
      if (targetPaths.isNotEmpty) {
        _startScan(targetPaths, newMode);
      } else {
        // 既没缓存也没路径，重置为空状态
        state = state.copyWith(
          scanMode: newMode,
          rootPaths: [],
          rawItems: [],
          treeRoot: [],
          totalCount: 0,
          statusMsg: "请添加文件夹",
          pathStack: [], // 重置面包屑
        );
      }
    }
    // 切换模式后重置面包屑
    state = state.copyWith(pathStack: const []);
  }

  // --- 动作：添加目录 ---
  Future<void> addDirectory() async {
    await PermissionService.requestExternalPermissions();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (!state.rootPaths.contains(selectedDirectory)) {
        final newPaths = [...state.rootPaths, selectedDirectory];

        await _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);

        state = state.copyWith(
          rootPaths: newPaths,
          statusMsg: "正在扫描新目录...",
        );
        _addFileWatcher(selectedDirectory);
        _scanSinglePath(selectedDirectory);
      }
    }
  }

  Future<void> clearAllDirectories() async {
    for (var sub in _fileWatchers.values) {
      sub.cancel();
    }
    _fileWatchers.clear();

    state = state.copyWith(
      rootPaths: [],
      rawItems: [],
      treeRoot: [],
      totalCount: 0,
      statusMsg: "已清空所有路径",
    );

    // [保持异步]
    await _cacheService.saveScanRootPaths([], mode: state.scanMode);
    await _cacheService.clearScanResults(mode: state.scanMode);
  }

  void removeDirectory(String pathToRemove) {
    _fileWatchers[pathToRemove]?.cancel();
    _fileWatchers.remove(pathToRemove);

    final updatedItems = state.rawItems.where((item) {
      return !item.path.startsWith(pathToRemove);
    }).toList();

    final newPaths = state.rootPaths.where((p) => p != pathToRemove).toList();

    _updateStateAndPersistence(updatedItems, newPaths, msg: "已移除目录");

    // [保持异步] fire-and-forget
    _cacheService.saveScanRootPaths(newPaths, mode: state.scanMode);
  }

  // --- 内部逻辑：扫描与更新 ---
  void _startScan(List<String> paths, ScanMode mode) {
    state = state.copyWith(
      rootPaths: paths,
      scanMode: mode,
      isScanning: true,
      rawItems: [],
      treeRoot: [],
      totalCount: 0,
      statusMsg: "正在扫描...",
    );

    final StreamController<List<AppMediaItem>> mergedController = StreamController();
    int activeStreams = 0;

    final validPaths = paths.where((p) => Directory(p).existsSync()).toList();

    if (validPaths.isEmpty) {
      mergedController.close();
      state = state.copyWith(isScanning: false, statusMsg: "路径无效");
      return;
    }

    for (final path in validPaths) {
      activeStreams++;
      Stream<List<AppMediaItem>> stream;
      switch (mode) {
        case ScanMode.audio:
          stream = ScannerService.scanAudioStream(path);
          break;
        case ScanMode.video:
          stream = ScannerService.scanVideoStream(path);
          break;
        case ScanMode.subtitles:
          stream = ScannerService.scanSubtitleStream(path);
          break;
      }

      stream.listen(
            (batch) { if (!mergedController.isClosed) mergedController.add(batch); },
        onDone: () {
          activeStreams--;
          if (activeStreams == 0 && !mergedController.isClosed) mergedController.close();
        },
        onError: (e) {
          activeStreams--;
          if (activeStreams == 0 && !mergedController.isClosed) mergedController.close();
        },
      );
    }

    List<AppMediaItem> accumulator = [];
    DateTime lastUiUpdateTime = DateTime.now();
    const throttleDuration = Duration(milliseconds: 500);

    _scanSubscription = mergedController.stream.listen(
            (batch) {
          accumulator.addAll(batch);
          final now = DateTime.now();
          if (now.difference(lastUiUpdateTime) > throttleDuration) {
            _updateStateAndPersistence(
                accumulator,
                paths,
                msg: "正在扫描...已发现 ${accumulator.length} 个文件"
            );
            lastUiUpdateTime = now;
          } else {
            state = state.copyWith(statusMsg: "正在扫描...已发现 ${accumulator.length} 个文件");
          }
        },
        onDone: () {
          _updateStateAndPersistence(accumulator, paths, msg: "扫描完成");
          _setupFileWatchers(paths);
        },
        onError: (e) {
          state = state.copyWith(isScanning: false, statusMsg: "扫描出错: $e");
          _setupFileWatchers(paths);
        }
    );
  }

  void _scanSinglePath(String path) {
    state = state.copyWith(isScanning: true);
    _scanSubscription?.cancel();

    Stream<List<AppMediaItem>> stream;
    switch (state.scanMode) {
      case ScanMode.audio:
        stream = ScannerService.scanAudioStream(path);
        break;
      case ScanMode.video:
        stream = ScannerService.scanVideoStream(path);
        break;
      case ScanMode.subtitles:
        stream = ScannerService.scanSubtitleStream(path);
        break;
    }

    List<AppMediaItem> newItemsFromPath = [];

    _scanSubscription = stream.listen(
          (batch) {
        newItemsFromPath.addAll(batch);
      },
      onDone: () {
        final allItems = [...state.rawItems, ...newItemsFromPath];
        _updateStateAndPersistence(
            allItems,
            state.rootPaths,
            msg: "添加完成，新增 ${newItemsFromPath.length} 个文件"
        );
      },
      onError: (e) {
        state = state.copyWith(isScanning: false, statusMsg: "扫描出错: $e");
      },
    );
  }

  void _updateStateAndPersistence(List<AppMediaItem> items, List<String> paths, {String? msg}) {
    final newTree = MediaTreeBuilder.build(items, paths);

    state = state.copyWith(
      isScanning: false,
      rootPaths: paths,
      rawItems: items,
      treeRoot: newTree,
      totalCount: items.length,
      statusMsg: msg ?? state.statusMsg,
    );

    // [保持异步] 写入操作
    _cacheService.saveScanResults(items, mode: state.scanMode);
  }

  // --- 重命名逻辑 (保持不变，只是调用监听恢复) ---
  Future<bool> renamePath(String oldPath, String newNameWithoutExtension) async {
    final hasPermission = await PermissionService.requestExternalPermissions();
    if (!hasPermission) {
      state = state.copyWith(statusMsg: "需要存储权限才能管理文件");
      return false;
    }

    _stopAllWatchers();

    try {
      final oldFile = File(oldPath);
      final oldDir = Directory(oldPath);
      final isDir = oldDir.existsSync();
      final isFile = oldFile.existsSync();

      if (!isDir && !isFile) {
        state = state.copyWith(statusMsg: "无法重命名：文件或目录不存在");
        _setupFileWatchers(state.rootPaths);
        return false;
      }

      final directory = p.dirname(oldPath);
      String extension = "";
      if (isFile) {
        extension = p.extension(oldPath);
      }
      final newFileName = "$newNameWithoutExtension$extension";
      final newPath = p.join(directory, newFileName);

      if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
        state = state.copyWith(statusMsg: "重命名失败：目标已存在");
        _setupFileWatchers(state.rootPaths);
        return false;
      }

      bool physicalSuccess = false;
      try {
        if (isFile) {
          await oldFile.rename(newPath);
        } else {
          await oldDir.rename(newPath);
        }
        physicalSuccess = true;
      } catch (e) {
        debugPrint("直接 Rename 失败 ($e)，尝试【复制-删除】策略...");
      }

      if (!physicalSuccess) {
        state = state.copyWith(statusMsg: "重命名失败：系统限制或文件被占用");
        _setupFileWatchers(state.rootPaths);
        return false;
      }

      List<AppMediaItem> newRawItems = [];
      bool anyChanged = false;

      String normalize(String path) => path.replaceAll('\\', '/');
      final normalizedOldPath = normalize(oldPath);
      final normalizedNewPath = normalize(newPath);

      for (var item in state.rawItems) {
        final normalizedItemPath = normalize(item.path);

        if (normalizedItemPath == normalizedOldPath) {
          newRawItems.add(item.copyWith(path: newPath, fileName: newFileName, title: newFileName));
          anyChanged = true;
        } else if (normalizedItemPath.startsWith("$normalizedOldPath/")) {
          final suffix = normalizedItemPath.substring(normalizedOldPath.length);
          final newSubPath = "$normalizedNewPath$suffix";

          String newAlbum = item.album;
          if (item.album == p.basename(oldPath) || item.album == p.basenameWithoutExtension(oldPath)) {
            newAlbum = newFileName;
          }
          newRawItems.add(item.copyWith(path: newSubPath, album: newAlbum));
          anyChanged = true;
        } else {
          newRawItems.add(item);
        }
      }

      if (anyChanged) {
        _updateStateAndPersistence(newRawItems, state.rootPaths, msg: "重命名成功");
      } else {
        state = state.copyWith(statusMsg: "重命名成功");
      }

      return true;

    } catch (e) {
      debugPrint("重命名流程严重错误: $e");
      state = state.copyWith(statusMsg: "重命名出错: $e");
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _setupFileWatchers(state.rootPaths);
    }
  }

  // --- 文件监听逻辑 (保持不变) ---
  void _stopAllWatchers() {
    debugPrint("正在暂停文件监听以释放句柄...");
    for (var sub in _fileWatchers.values) {
      sub.cancel();
    }
    _fileWatchers.clear();
  }

  void _setupFileWatchers(List<String> paths) {
    for (var sub in _fileWatchers.values) {
      sub.cancel();
    }
    _fileWatchers.clear();
    for (var path in paths) {
      _addFileWatcher(path);
    }
  }

  void _addFileWatcher(String path) {
    if (_fileWatchers.containsKey(path)) return;
    final dir = Directory(path);
    if (!dir.existsSync()) return;

    try {
      final stream = dir.watch(recursive: true);
      _fileWatchers[path] = stream.listen((event) {
        _handleFileSystemEvent(event);
      });
    } catch (e) {
      print("监听目录失败: $path, $e");
    }
  }

  Future<void> _handleFileSystemEvent(FileSystemEvent event) async {
    if (event.isDirectory) return;

    if (event.type == FileSystemEvent.create) {
      final file = File(event.path);
      if (_isValidExtension(event.path)) {
        final newItem = await ScannerService.parseFile(file, mode: state.scanMode);
        if (newItem != null) {
          if (!state.rawItems.contains(newItem)) {
            final newItems = [...state.rawItems, newItem];
            _updateStateAndPersistence(newItems, state.rootPaths, msg: "检测到新文件");
          }
        }
      }
    } else if (event.type == FileSystemEvent.delete) {
      final existingIndex = state.rawItems.indexWhere((item) => item.path == event.path);
      if (existingIndex != -1) {
        final newItems = List<AppMediaItem>.from(state.rawItems);
        newItems.removeAt(existingIndex);
        _updateStateAndPersistence(newItems, state.rootPaths, msg: "文件已移除");
      }
    }
  }

  bool _isValidExtension(String path) {
    final ext = path.toLowerCase().split('.').last;
    final dotExt = '.$ext';
    switch (state.scanMode) {
      case ScanMode.audio:
        return FileExtensions.audio.contains(dotExt);
      case ScanMode.video:
        return FileExtensions.video.contains(dotExt);
      case ScanMode.subtitles:
        return FileExtensions.subtitles.contains(dotExt);
    }
  }

  // --- 导航逻辑 (保持不变) ---
  void enterFolder(String folderName) {
    state = state.copyWith(pathStack: [...state.pathStack, folderName]);
  }

  void jumpToPathIndex(int index) {
    if (index == -1) {
      state = state.copyWith(pathStack: []);
    } else {
      if (index + 1 < state.pathStack.length) {
        state = state.copyWith(pathStack: state.pathStack.sublist(0, index + 1));
      }
    }
  }

  void navigateBack() {
    if (state.pathStack.isNotEmpty) {
      final newStack = List<String>.from(state.pathStack)..removeLast();
      state = state.copyWith(pathStack: newStack);
    }
  }

  Future<void> refreshAll() async {
    if (state.isScanning) return;
    if (state.rootPaths.isEmpty) {
      state = state.copyWith(statusMsg: "没有需要扫描的文件夹");
      return;
    }

    _scanSubscription?.cancel();
    _stopAllWatchers();

    state = state.copyWith(
      isScanning: true,
      rawItems: [],
      treeRoot: [],
      totalCount: 0,
      statusMsg: "正在刷新全部...",
    );

    final StreamController<List<AppMediaItem>> mergedController = StreamController();
    final validPaths = state.rootPaths
        .where((p) => Directory(p).existsSync())
        .toList();

    if (validPaths.isEmpty) {
      mergedController.close();
      state = state.copyWith(isScanning: false, statusMsg: "所有路径均无效");
      return;
    }
    _startScan(validPaths, state.scanMode);
  }
}

final fileScannerProvider = NotifierProvider.autoDispose<FileScannerNotifier, FileScannerState>(() {
  return FileScannerNotifier();
});