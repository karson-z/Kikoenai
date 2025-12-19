import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_file_extensions.dart';
import '../../../../core/model/app_media_item.dart';
import '../../../../core/service/cache_service.dart';
import '../../../../core/service/file_scanner_service.dart';
import '../../data/model/file_scanner_state.dart';
import '../../data/service/tree_service.dart';

class FileScannerNotifier extends Notifier<FileScannerState> {
  // 扫描流订阅（用于添加目录时的扫描）
  StreamSubscription? _scanSubscription;
  // 文件系统监听器 Map: Key=目录路径, Value=订阅
  final Map<String, StreamSubscription<FileSystemEvent>> _fileWatchers = {};

  @override
  FileScannerState build() {
    // 1. 销毁时的清理 (自动管理，无需在 refreshAll 里手动写)
    ref.onDispose(() {
      _scanSubscription?.cancel();
      for (var sub in _fileWatchers.values) {
        sub.cancel();
      }
    });

    // 2. 启动初始化逻辑 (使用 microtask 避免在 build 中直接 setState)
    Future.microtask(() => _initData());

    // 3. 返回初始空状态 (Riverpod 会在 invalidateSelf 后自动重置为这里的值)
    return const FileScannerState();
  }
  Future<void> _initData() async {
    final isAudio = state.isAudioMode;
    // A. 读取路径
    final paths = await CacheService.instance.getScanRootPaths(isAudio: isAudio);
    // 如果没有路径，直接结束
    if (paths.isEmpty) {
      state = state.copyWith(rootPaths: [], statusMsg: "请添加文件夹");
      return;
    }
    final cachedItems = await CacheService.instance.getCachedScanResults(isAudio: isAudio);
    if (cachedItems.isNotEmpty) {
      // 场景 1: 有缓存 -> 加载并显示
      _loadFromCache(paths, cachedItems, isAudio);
    } else {
      // 场景 2: 有路径但没缓存 (说明是第一次，或刚点击了刷新) -> 自动全量扫描
      _startScan(paths, isAudio);
    }
  }

  void _loadFromCache(List<String> paths, List<AppMediaItem> items, bool isAudio) {
    final tree = MediaTreeBuilder.build(items, paths);
    state = state.copyWith(
      rootPaths: paths,
      isAudioMode: isAudio,
      rawItems: items,
      treeRoot: tree,
      totalCount: items.length,
      statusMsg: "加载完成 (${items.length}个文件)",
    );
    _setupFileWatchers(paths);
  }
  void _startScan(List<String> paths, bool isAudio) {
    // 1. 更新状态为扫描中
    state = state.copyWith(
      rootPaths: paths,
      isAudioMode: isAudio,
      isScanning: true,
      rawItems: [], // 清空列表
      treeRoot: [],
      totalCount: 0,
      statusMsg: "正在扫描...",
    );

    // 2. 准备并发流
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
      final stream = isAudio
          ? ScannerService.scanAudioStream(path)
          : ScannerService.scanVideoStream(path);

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

    // 3. 订阅结果
    List<AppMediaItem> accumulator = [];
    _scanSubscription = mergedController.stream.listen(
            (batch) {
          accumulator.addAll(batch);
          // 实时更新 UI 计数
          state = state.copyWith(statusMsg: "已发现 ${accumulator.length} 个文件...");
        },
        onDone: () {
          // 扫描结束：保存 + 更新状态 + 开启监听
          _updateStateAndPersistence(accumulator, paths, msg: "扫描完成");
          _setupFileWatchers(paths);
        },
        onError: (e) {
          state = state.copyWith(isScanning: false, statusMsg: "扫描出错: $e");
          _setupFileWatchers(paths);
        }
    );
  }
  // --- 动作：添加目录 (增量逻辑) ---
  Future<void> addDirectory() async {

    PermissionService.requestExternalPermissions();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      // 检查重复
      if (!state.rootPaths.contains(selectedDirectory)) {
        final newPaths = [...state.rootPaths, selectedDirectory];

        // 1. 保存路径配置
        await CacheService.instance.saveScanRootPaths(newPaths,isAudio: state.isAudioMode);

        state = state.copyWith(
          rootPaths: newPaths,
          statusMsg: "正在扫描新目录...",
        );

        // 2. 开启新目录的监听
        _addFileWatcher(selectedDirectory);

        // 3. 仅扫描这个新目录 (增量更新)
        _scanSinglePath(selectedDirectory);
      }
    }
  }
  Future<void> clearAllDirectories() async {
    // 1. 取消所有监听
    for (var sub in _fileWatchers.values) sub.cancel();
    _fileWatchers.clear();

    // 2. 清空状态
    state = state.copyWith(
      rootPaths: [],
      rawItems: [],
      treeRoot: [],
      totalCount: 0,
      statusMsg: "已清空所有路径",
    );

    // 3. 清除持久化数据 (保存空列表)
    await CacheService.instance.saveScanRootPaths([], isAudio: state.isAudioMode);
    await CacheService.instance.clearScanResults(isAudio: state.isAudioMode);
  }
  // --- 动作：移除目录 (增量移除) ---
  void removeDirectory(String pathToRemove) {
    // 1. 移除监听
    _fileWatchers[pathToRemove]?.cancel();
    _fileWatchers.remove(pathToRemove);

    // 2. 从内存列表中过滤掉该路径下的文件
    // 假设 item.path 是绝对路径，我们检查是否以此目录开头
    final updatedItems = state.rawItems.where((item) {
      return !item.path.startsWith(pathToRemove);
    }).toList();

    // 3. 更新路径列表
    final newPaths = state.rootPaths.where((p) => p != pathToRemove).toList();

    // 4. 更新状态并持久化
    _updateStateAndPersistence(updatedItems, newPaths, msg: "已移除目录");

    // 5. 保存路径配置
    CacheService.instance.saveScanRootPaths(newPaths,isAudio: state.isAudioMode);
  }

  // --- 内部逻辑：扫描单个路径 ---
  void _scanSinglePath(String path) {
    state = state.copyWith(isScanning: true);

    // 取消之前的扫描流（如果有正在进行的）
    _scanSubscription?.cancel();

    final stream = state.isAudioMode
        ? ScannerService.scanAudioStream(path)
        : ScannerService.scanVideoStream(path);

    // 临时存储新扫描到的文件
    List<AppMediaItem> newItemsFromPath = [];

    _scanSubscription = stream.listen(
          (batch) {
        newItemsFromPath.addAll(batch);
        // 可选：如果希望扫描过程中实时看到数字跳动，可以在这里做中间态更新
      },
      onDone: () {
        // 扫描完成，合并旧数据和新数据
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

  // --- 内部逻辑：文件监听 (Watch) ---
  void _setupFileWatchers(List<String> paths) {
    // 清理旧的（防止重复）
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
      // recursive: true 很重要，监听子文件夹
      final stream = dir.watch(recursive: true);
      _fileWatchers[path] = stream.listen((event) {
        _handleFileSystemEvent(event);
      });
    } catch (e) {
      print("监听目录失败: $path, $e");
    }
  }

  // 处理文件增删事件
  Future<void> _handleFileSystemEvent(FileSystemEvent event) async {
    if (event.isDirectory) return; // 忽略文件夹本身的变动

    // 1. 处理新增文件
    if (event.type == FileSystemEvent.create) {
      final file = File(event.path);
      if (_isValidExtension(event.path)) {
        // 解析新文件
        final currentMode = state.isAudioMode ? ScanMode.audio : ScanMode.video;
        final newItem = await ScannerService.parseFile(file,mode: currentMode);
        if (newItem != null) {
          // 检查是否已存在（防止重复添加）
          if (!state.rawItems.contains(newItem)) {
            final newItems = [...state.rawItems, newItem];
            _updateStateAndPersistence(newItems, state.rootPaths, msg: "检测到新文件");
          }
        }
      }
    }
    // 2. 处理删除文件
    else if (event.type == FileSystemEvent.delete) {
      // 找到并移除
      final existingIndex = state.rawItems.indexWhere((item) => item.path == event.path);
      if (existingIndex != -1) {
        final newItems = List<AppMediaItem>.from(state.rawItems);
        newItems.removeAt(existingIndex);
        _updateStateAndPersistence(newItems, state.rootPaths, msg: "文件已移除");
      }
    }
  }

  // 检查后缀名
  bool _isValidExtension(String path) {
    final ext = path.toLowerCase().split('.').last;

    if (state.isAudioMode) return FileExtensions.audio.contains(ext);
    return FileExtensions.video.contains(ext);
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

    CacheService.instance.saveScanResults(items, isAudio: state.isAudioMode);
  }

  // 进入文件夹
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
  ///切换 扫描的文件模式（音频/视频）
  Future<void> toggleMode(bool isAudio) async {
    if (state.isAudioMode == isAudio) return;

    // 1. 获取目标模式的路径
    final targetPaths = await CacheService.instance.getScanRootPaths(isAudio: isAudio);

    // 2. 获取目标模式的缓存结果
    final targetItems = await CacheService.instance.getCachedScanResults(isAudio: isAudio);

    if (targetItems.isNotEmpty) {
      // 有缓存 -> 直接显示
      _loadFromCache(targetPaths, targetItems, isAudio);
    } else {
      // 无缓存 -> 使用目标路径进行扫描 (如果路径不为空)
      _startScan(targetPaths, isAudio);
    }
    state = state.copyWith(pathStack: const []);
  }
  Future<void> refreshAll() async {
    // 1. 防止重复点击
    if (state.isScanning) return;
    if (state.rootPaths.isEmpty) {
      state = state.copyWith(statusMsg: "没有需要扫描的文件夹");
      return;
    }

    // 2. 清理当前状态 (停止监听，清空列表)
    _scanSubscription?.cancel();
    // 暂时取消文件监听，防止扫描过程中产生冲突事件
    for (var sub in _fileWatchers.values) {
      sub.cancel();
    }
    _fileWatchers.clear();

    state = state.copyWith(
      isScanning: true,
      rawItems: [], // 清空当前显示，或者你可以选择保留旧数据直到新数据加载完成
      treeRoot: [],
      totalCount: 0,
      statusMsg: "正在刷新全部...",
    );

    // 3. 准备并发扫描流
    // 我们创建一个合并的 Controller 来统一接收所有目录的扫描结果
    final StreamController<List<AppMediaItem>> mergedController = StreamController();
    int activeStreams = 0;

    // 过滤出有效的路径
    final validPaths = state.rootPaths.where((p) => Directory(p).existsSync()).toList();

    if (validPaths.isEmpty) {
      mergedController.close();
      state = state.copyWith(isScanning: false, statusMsg: "所有路径均无效");
      return;
    }

    // 4. 启动所有路径的扫描
    for (final path in validPaths) {
      activeStreams++;
      final stream = state.isAudioMode
          ? ScannerService.scanAudioStream(path)
          : ScannerService.scanVideoStream(path);

      stream.listen(
            (batch) {
          if (!mergedController.isClosed) mergedController.add(batch);
        },
        onDone: () {
          activeStreams--;
          if (activeStreams == 0 && !mergedController.isClosed) {
            mergedController.close();
          }
        },
        onError: (e) {
          print("扫描路径出错 $path: $e");
          activeStreams--;
          if (activeStreams == 0 && !mergedController.isClosed) {
            mergedController.close();
          }
        },
      );
    }

    // 5. 订阅合并后的结果
    List<AppMediaItem> accumulator = [];

    _scanSubscription = mergedController.stream.listen(
            (batch) {
          accumulator.addAll(batch);
          // 可选：实时更新计数
          state = state.copyWith(statusMsg: "扫描中... 已发现 ${accumulator.length} 个文件");
        },
        onDone: () {
          // 全部扫描完成
          _updateStateAndPersistence(
              accumulator,
              state.rootPaths,
              msg: "刷新完成，共 ${accumulator.length} 个文件"
          );
          // 重新开启文件监听
          _setupFileWatchers(state.rootPaths);
        },
        onError: (e) {
          state = state.copyWith(isScanning: false, statusMsg: "刷新过程出错: $e");
          _setupFileWatchers(state.rootPaths); // 出错也要恢复监听
        }
    );
  }
}

// 3. 定义 Provider
final fileScannerProvider = NotifierProvider.autoDispose<FileScannerNotifier, FileScannerState>(() {
  return FileScannerNotifier();
});