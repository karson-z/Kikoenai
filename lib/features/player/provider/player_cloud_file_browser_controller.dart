import 'package:flutter/foundation.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_browser_state.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'player_cloud_file_source_provider.dart';

/// 单个播放页弹层的浏览会话，不复用网盘主页的路径、选择和搜索状态。
class PlayerCloudFileBrowserController extends ChangeNotifier {
  PlayerCloudFileBrowserController(this.source)
    : path = source.origin.parentPath,
      state = CloudDriveBrowserState(
        supportsPagination: source.supportsPagination,
      );

  final BoundPlayerCloudSource source;
  final Map<String, CloudDriveBrowserState> _directories = {};
  final Map<String, FileNode> _selected = {};
  String path;
  CloudDriveBrowserState state;
  int _requestVersion = 0;
  bool _disposed = false;
  bool isLocating = false;

  String get rootPath => FileOrigin.normalizePath(source.origin.rootPath);
  bool get isAtRoot => path == rootPath;
  List<FileNode> get selected => _selected.values.toList(growable: false);
  bool isSelected(FileNode node) => _selected.containsKey(_key(node));
  bool get allLoadedSelected =>
      state.nodes.isNotEmpty && state.nodes.every(isSelected);
  bool get isCurrentDirectory => path == source.origin.parentPath;
  bool get containsCurrentFile =>
      state.nodes.any((node) => node.path == source.origin.filePath);

  static String _key(FileNode node) => node.path ?? node.remoteId ?? node.keyId;

  void toggle(FileNode node) {
    final key = _key(node);
    if (_selected.containsKey(key)) {
      _selected.remove(key);
    } else {
      _selected[key] = node;
    }
    notifyListeners();
  }

  void toggleAllLoaded() {
    if (allLoadedSelected) {
      for (final node in state.nodes) {
        _selected.remove(_key(node));
      }
    } else {
      for (final node in state.nodes) {
        _selected[_key(node)] = node;
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void setSort(CloudDriveSort sort) {
    state = state.copyWith(sort: sort);
    notifyListeners();
  }

  Future<void> navigate(String target) async {
    final next = FileOrigin.normalizePath(target);
    if (next == path) return;
    if (!source.origin.contains(next)) return;
    _directories[path] = state.copyWith(
      isLoading: false,
      isLoadingMore: false,
      errorMessage: null,
    );
    _requestVersion++;
    isLocating = false;
    path = next;
    final cached = _directories[next];
    state =
        cached?.copyWith(sort: state.sort) ??
        CloudDriveBrowserState(
          supportsPagination: source.supportsPagination,
          sort: state.sort,
        );
    notifyListeners();
    if (!state.hasLoadedDirectory) await refresh();
  }

  Future<void> parent() =>
      isAtRoot ? Future.value() : navigate(NodeFolder.dirName(path));

  Future<void> refresh() async {
    final version = ++_requestVersion;
    isLocating = false;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      errorMessage: null,
    );
    notifyListeners();
    try {
      final result = await source.list(path: path, page: 1, pageSize: 50);
      if (_disposed || version != _requestVersion) return;
      final nodes = _unique(result.items);
      state = state.copyWith(
        nodes: nodes,
        currentPage: 1,
        totalCount: result.items.isEmpty ? 0 : result.totalCount,
        isLoading: false,
      );
      // 刷新只清理当前目录中已确认消失的选项；后续分页不作不存在判定。
      if (!state.hasMore) {
        final keys = nodes.map(_key).toSet();
        _selected.removeWhere(
          (key, node) =>
              NodeFolder.dirName(node.path ?? '') == path &&
              !keys.contains(key),
        );
      }
    } catch (error) {
      if (_disposed || version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: source.describeError(error),
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final version = _requestVersion;
    final requestPath = path;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    notifyListeners();
    try {
      final page = state.currentPage + 1;
      final result = await source.list(
        path: requestPath,
        page: page,
        pageSize: 50,
      );
      if (_disposed || version != _requestVersion) return;
      final nodes = _unique([...state.nodes, ...result.items]);
      final exhausted = nodes.length == state.nodes.length;
      state = state.copyWith(
        nodes: nodes,
        currentPage: page,
        totalCount: exhausted ? nodes.length : result.totalCount,
        isLoadingMore: false,
      );
    } catch (error) {
      if (_disposed || version != _requestVersion) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: source.describeError(error),
      );
    }
    notifyListeners();
  }

  /// 用户主动定位时才继续读取后续页，避免打开弹层就遍历大目录。
  Future<void> locateCurrentFile() async {
    if (isLocating || state.isLoading || state.isLoadingMore) return;
    if (!isCurrentDirectory) await navigate(source.origin.parentPath);
    if (_disposed || !isCurrentDirectory) return;
    final version = _requestVersion;
    isLocating = true;
    notifyListeners();
    while (!_disposed &&
        version == _requestVersion &&
        !containsCurrentFile &&
        state.hasMore &&
        state.errorMessage == null) {
      await loadMore();
    }
    if (_disposed || version != _requestVersion) return;
    isLocating = false;
    notifyListeners();
  }

  static List<FileNode> _unique(List<FileNode> nodes) {
    final seen = <String>{};
    return nodes.where((node) => seen.add(_key(node))).toList(growable: false);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
