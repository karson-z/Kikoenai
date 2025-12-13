import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// --- 1. 根目录 Provider (AsyncValue) ---
// 负责计算并确保根目录存在
final rootPathProvider = FutureProvider.autoDispose.family<String, String?>((ref, manualRoot) async {
  String root;
  if (manualRoot != null && manualRoot.isNotEmpty) {
    root = manualRoot;
  } else {
    final appDocDir = await getApplicationDocumentsDirectory();
    root = p.join(appDocDir.path, 'SmartImports');
  }

  final dir = Directory(root);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return root;
});

// --- 2. 当前路径 Provider (Notifier) ---
// 负责管理用户当前所在的路径，提供跳转、返回上一级等方法
class CurrentPathNotifier extends Notifier<String?> {
  @override
  String? build() {
    // 初始状态为 null，等待 rootPath 加载完成后由 UI 层初始化
    return null;
  }

  void setPath(String path) {
    state = path;
  }

  void navigateTo(String path) {
    if (FileSystemEntity.isDirectorySync(path)) {
      state = path;
    }
  }

  void navigateUp(String rootPath) {
    if (state == null) return;
    // 如果已经在根目录，不操作
    if (p.equals(p.normalize(state!), p.normalize(rootPath))) return;

    // 获取父级目录
    final parent = Directory(state!).parent.path;
    // 防止跳出根目录 (安全检查)
    if (p.isWithin(rootPath, parent) || p.equals(p.normalize(parent), p.normalize(rootPath))) {
      state = parent;
    }
  }
}

final currentPathProvider = NotifierProvider.autoDispose<CurrentPathNotifier, String?>(() {
  return CurrentPathNotifier();
});


// --- 3. 文件列表 Provider (FutureProvider) ---
// 监听 currentPathProvider，一旦路径改变，自动重新读取文件
final fileListProvider = FutureProvider.autoDispose<List<FileSystemEntity>>((ref) async {
  final currentPath = ref.watch(currentPathProvider);

  // 如果路径还没初始化，返回空
  if (currentPath == null) return [];

  final dir = Directory(currentPath);
  if (!await dir.exists()) {
    // 如果当前目录被删了，理论上应该报错或通知上层回退，这里简单返回空
    return [];
  }

  final entities = dir.listSync();

  // 排序逻辑：文件夹在前，文件在后，按名称排序
  entities.sort((a, b) {
    final typeA = FileSystemEntity.typeSync(a.path);
    final typeB = FileSystemEntity.typeSync(b.path);

    if (typeA == typeB) {
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    }
    return typeA == FileSystemEntityType.directory ? -1 : 1;
  });

  return entities;
});