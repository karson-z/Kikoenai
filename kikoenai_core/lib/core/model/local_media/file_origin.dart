import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kikoenai_core/core/constants/type_ids.dart';
import 'package:path/path.dart' as p;

part 'file_origin.g.dart';

@HiveType(typeId: TypeIds.fileOriginKind)
enum FileOriginKind {
  @HiveField(0)
  alist,
  @HiveField(1)
  webDav,
}

/// 文件系统位置，与作品身份及可能过期的播放 URL 分开保存。
/// connectionId 仅标识来源，不包含密码、令牌或签名。
@JsonSerializable()
@HiveType(typeId: TypeIds.fileOrigin)
class FileOrigin {
  const FileOrigin({
    required this.kind,
    required this.connectionId,
    required this.filePath,
    this.rootPath = '/',
  });

  @HiveField(0)
  final FileOriginKind kind;
  @HiveField(1)
  final String connectionId;
  @HiveField(2)
  final String filePath;
  @HiveField(3, defaultValue: '/')
  final String rootPath;

  String get parentPath => p.posix.dirname(normalizePath(filePath));

  FileOrigin atPath(String path) => FileOrigin(
    kind: kind,
    connectionId: connectionId,
    filePath: normalizePath(path),
    rootPath: normalizePath(rootPath),
  );

  bool contains(String path) {
    final root = normalizePath(rootPath);
    final target = normalizePath(path);
    return root == '/' || target == root || target.startsWith('$root/');
  }

  static String normalizePath(String value) =>
      p.posix.normalize('/${value.replaceAll('\\', '/')}');

  factory FileOrigin.fromJson(Map<String, dynamic> json) =>
      _$FileOriginFromJson(json);

  /// MediaItem extras may cross a JSON/platform channel and lose map types.
  static FileOrigin? tryParse(Object? value) {
    if (value is FileOrigin) return value;
    if (value is! Map) return null;
    try {
      final origin = FileOrigin.fromJson(Map<String, dynamic>.from(value));
      if (origin.connectionId.isEmpty ||
          !origin.filePath.startsWith('/') ||
          !origin.contains(origin.filePath)) {
        return null;
      }
      return origin;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => _$FileOriginToJson(this);

  static Map<String, dynamic>? encode(FileOrigin? value) => value?.toJson();

  @override
  bool operator ==(Object other) =>
      other is FileOrigin &&
      other.kind == kind &&
      other.connectionId == connectionId &&
      other.filePath == filePath &&
      other.rootPath == rootPath;

  @override
  int get hashCode => Object.hash(kind, connectionId, filePath, rootPath);
}
