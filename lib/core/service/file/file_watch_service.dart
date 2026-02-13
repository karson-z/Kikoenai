import 'dart:async';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:watcher/watcher.dart';
import '../cache/cache_service.dart';

class FileWatcher {
  final CacheService cacheService = CacheService.instance;
  // 存储路径与对应的订阅对象，方便精准销毁
  final Map<String, StreamSubscription<WatchEvent>> _subscriptions = {};

  ///  获取用户选择的路径集合
  List<String> getDirPath() {
    final allPath = cacheService.getScanRootPaths();
    return allPath;
  }

  /// 初始化：为所有路径开启监听
  void initAllListeners() {
    final paths = getDirPath();
    if(paths.isEmpty) return;
    for (var path in paths) {
      addDirListener(path);
    }
  }

  /// 添加单个目录监听
  void addDirListener(String path) {
    if (_subscriptions.containsKey(path)) return;
    // DirectoryWatcher 会自动根据平台选择最优底层实现
    final watcher = DirectoryWatcher(path);
    final subscription = watcher.events.listen(
          (event) => _handleFileEvent(event),
      onError: (e) => KikoenaiLogger().e('Path $path watch error: $e'),
      cancelOnError: false,
    );
    _subscriptions[path] = subscription;
  }

  /// 移除监听（例如用户取消了某个文件夹的勾选）
  void removeDirListener(String path) {
    _subscriptions[path]?.cancel();
    _subscriptions.remove(path);
  }

  /// 事件处理中心
  void _handleFileEvent(WatchEvent event) {
    // 根据事件类型（add, remove, modify）执行缓存重构
    switch (event.type) {
      case ChangeType.ADD:
      // TODO: 调用 dart:io 扫描新文件并写入缓存，更新 UI
        break;
      case ChangeType.REMOVE:
      // TODO: 从缓存删除对应路径，更新 UI
        break;
      case ChangeType.MODIFY:
      // TODO: 更新缓存中的 mtime 等元数据
        break;
    }
    print('Event: ${event.type} on ${event.path}');
  }

  /// 销毁所有资源
  void dispose() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}