import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import '../constants/app_typeIds.dart';

part 'file_node.freezed.dart';
part 'file_node.g.dart';

@HiveType(typeId: TypeIds.nodeSource)
enum NodeSource {
  @HiveField(0)
  asmrServer,
  @HiveField(1)
  localWork,
  @HiveField(2)
  localSingle,
  @HiveField(3)
  cloudDrive,
}

@HiveType(typeId: TypeIds.nodeType)
enum NodeType {
  @HiveField(0)
  folder,
  @HiveField(1)
  audio,
  @HiveField(2)
  image,
  @HiveField(3)
  text,
  @HiveField(4)
  video,
  @HiveField(5)
  other,
  @HiveField(6)
  unknown,
}

@HiveType(typeId: TypeIds.nodeStatus)
enum NodeStatus {
  @HiveField(0)
  normal,
  @HiveField(1)
  pending,
  @HiveField(2)
  parsing,
  @HiveField(3)
  parsed;

  bool get isPending => this == NodeStatus.pending;
  bool get isProcessing => this == NodeStatus.parsing;
  bool get isCompleted => this == NodeStatus.parsed;
}

@freezed
@HiveType(typeId: TypeIds.fileNode, adapterName: 'FileNodeAdapter')
abstract class FileNode extends HiveObject with _$FileNode {
  factory FileNode({
    @HiveField(0) required NodeType type,
    @HiveField(1) required String title,
    List<FileNode>? children,
    @HiveField(2) String? hash,
    @HiveField(3) String? mediaStreamUrl,
    @HiveField(4) String? mediaDownloadUrl,
    @HiveField(5) double? duration,
    @HiveField(6) int? size,
    @HiveField(7) String? workTitle,
    @HiveField(8) String? artist,
    @HiveField(9) @Default(0) int lastModified,
    @HiveField(10) @Default(NodeStatus.normal) NodeStatus nodeStatus,
    @HiveField(11) int? workId,
    @HiveField(12) @Default(NodeSource.asmrServer) NodeSource source,

    // Media-library index fields.
    @HiveField(13) String? path,
    @HiveField(14) String? folderPath,
    @HiveField(15) String? rootPath,
    @HiveField(16) String? parentPath,
    @HiveField(17) @Default(0) int depth,
    @Default(0) int subItemsCount,
  }) = _FileNode;

  FileNode._();

  bool get isFolder => type == NodeType.folder;
  bool get isAudio => type == NodeType.audio;
  bool get isImage => type == NodeType.image;
  bool get isText => type == NodeType.text;
  bool get isVideo => type == NodeType.video;
  bool get isOther => type == NodeType.other;

  bool get isPlayable => isAudio || isVideo;

  /// Stable identity for cache/index lookup.
  /// Prefer path, then playable URL, then hash.
  String get keyId => hash ?? path ?? mediaStreamUrl ?? '';

  /// Actual playback/read path. Local file path or remote URL.
  String get playablePath => mediaStreamUrl ?? path ?? '';

  /// Internal path used by folder index.
  String get effectivePath => path ?? mediaStreamUrl ?? hash ?? title;

  NodeFolder? get folder {
    final p = folderPath;
    if (p == null || p.isEmpty) return null;
    return NodeFolder(p);
  }

  bool get isLocal =>
      source == NodeSource.localWork || source == NodeSource.localSingle;
  bool get isRemote =>
      source == NodeSource.asmrServer || source == NodeSource.cloudDrive;

  bool get isAsmrServer => source == NodeSource.asmrServer;
  bool get isLocalWork => source == NodeSource.localWork;
  bool get isLocalSingle => source == NodeSource.localSingle;
  bool get isCloudDrive => source == NodeSource.cloudDrive;

  factory FileNode.fromJson(Map<String, dynamic> json) =>
      _$FileNodeFromJson(json);
}

class NodeFolder {
  final String path;

  const NodeFolder(this.path);

  String get normalized {
    return normalizePath(path);
  }

  String get key => normalized.toLowerCase();

  String get name {
    return baseName(normalized);
  }

  NodeFolder? get parent {
    final parentPath = dirName(normalized);
    if (parentPath == normalized || parentPath == '.') return null;
    return NodeFolder(parentPath);
  }

  List<NodeFolder> buildInbetweenFolders({String? stopAtRootPath}) {
    final rootFolder = stopAtRootPath == null
        ? null
        : NodeFolder(stopAtRootPath);
    if (rootFolder != null) {
      final normalizedRoot = rootFolder.normalized;
      final normalizedRootLower = normalizedRoot.toLowerCase();
      final normalizedLower = normalized.toLowerCase();
      if (normalizedLower == normalizedRootLower) return const [];
      if (normalizedLower.startsWith('$normalizedRootLower/')) {
        final relative = normalized.substring(normalizedRoot.length);
        final parts = relative.split('/').where((e) => e.isNotEmpty);
        final result = <NodeFolder>[];
        var currentPath = normalizedRoot;

        for (final part in parts) {
          currentPath = joinPath(currentPath, part);
          result.add(NodeFolder(currentPath));
        }

        return result;
      }
    }

    final result = <NodeFolder>[];
    NodeFolder? cursor = this;
    while (cursor != null) {
      result.insert(0, cursor);
      cursor = cursor.parent;
    }

    return result;
  }

  bool hasSamePathAs(String path) => key == NodeFolder(path).key;

  static String normalizePath(String path) {
    final posix = p.Context(style: p.Style.posix);
    final normalizedSeparators = path.replaceAll('\\', '/');
    final uriMatch = _uriPathPattern.firstMatch(normalizedSeparators);
    if (uriMatch != null) {
      final prefix = uriMatch.group(1)!;
      final body = uriMatch.group(2)!;
      final normalizedBody = posix
          .normalize(body)
          .replaceFirst(RegExp(r'^/+'), '');
      return '$prefix$normalizedBody';
    }
    return posix.normalize(normalizedSeparators);
  }

  static String dirName(String path) {
    final posix = p.Context(style: p.Style.posix);
    final normalizedPath = normalizePath(path);
    final uriMatch = _uriPathPattern.firstMatch(normalizedPath);
    if (uriMatch != null) {
      final prefix = uriMatch.group(1)!;
      final body = uriMatch.group(2)!;
      final parent = posix.dirname(body);
      if (parent == '.' || parent == body) return normalizedPath;
      return '$prefix$parent';
    }
    return posix.dirname(normalizedPath);
  }

  static String baseName(String path) {
    final posix = p.Context(style: p.Style.posix);
    final normalizedPath = normalizePath(path);
    final uriMatch = _uriPathPattern.firstMatch(normalizedPath);
    if (uriMatch != null) {
      return posix.basename(uriMatch.group(2)!);
    }
    return posix.basename(normalizedPath);
  }

  static String joinPath(String parent, String child) {
    final normalizedParent = normalizePath(parent);
    final normalizedChild = child.replaceAll('\\', '/');
    return normalizePath('$normalizedParent/$normalizedChild');
  }

  static final _uriPathPattern = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.-]*://)(.*)$');

  @override
  bool operator ==(Object other) {
    return other is NodeFolder && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'NodeFolder($normalized)';
}
