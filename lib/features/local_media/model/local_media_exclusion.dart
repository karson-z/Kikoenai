import 'package:kikoenai_core/kikoenai_core.dart';

/// 一条按扫描根目录隔离的本地排除记录。
class LocalMediaExclusion {
  const LocalMediaExclusion({
    required this.rootPath,
    required this.relativePath,
    required this.isFolder,
  });

  final String rootPath;
  final String relativePath;
  final bool isFolder;

  String get storageKey => '$rootPath|$relativePath|${isFolder ? 'd' : 'f'}';

  Map<String, Object> toJson() => {
    'rootPath': rootPath,
    'relativePath': relativePath,
    'isFolder': isFolder,
  };

  static LocalMediaExclusion? fromJson(Object? value) {
    if (value is! Map) return null;
    final rootPath = value['rootPath'];
    final relativePath = value['relativePath'];
    final isFolder = value['isFolder'];
    if (rootPath is! String ||
        rootPath.isEmpty ||
        relativePath is! String ||
        relativePath.isEmpty ||
        isFolder is! bool) {
      return null;
    }
    return LocalMediaExclusion(
      rootPath: NodeFolder.normalizePath(rootPath),
      relativePath: relativePath,
      isFolder: isFolder,
    );
  }
}
