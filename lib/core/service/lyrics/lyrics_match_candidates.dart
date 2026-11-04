import 'package:audio_service/audio_service.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 所有标题策略共用的目录筛选，避免后续兜底再次跨目录误配。
class LyricsMatchCandidates {
  LyricsMatchCandidates(List<FileNode> lyrics)
    : _lyrics = lyrics,
      _folders = {
        for (final lyric in lyrics)
          lyric: _MatchFolder.fromPath(
            lyric.path ?? lyric.fileOrigin?.filePath ?? lyric.mediaStreamUrl,
            folder: lyric.folderPath ?? lyric.parentPath,
            root: lyric.rootPath ?? lyric.fileOrigin?.rootPath,
          ),
      };

  final List<FileNode> _lyrics;
  final Map<FileNode, _MatchFolder?> _folders;

  List<FileNode> forAudio(MediaItem audio) {
    final extras = audio.extras;
    final origin = FileOrigin.tryParse(extras?['fileOrigin']);
    final folder = _MatchFolder.fromPath(
      extras?['path'] as String? ??
          origin?.filePath ??
          extras?['url'] as String? ??
          audio.id,
      folder: extras?['folderPath'] as String?,
      root: extras?['rootPath'] as String? ?? origin?.rootPath,
    );
    if (folder == null) return _lyrics;

    var bestRank = (0, 0);
    final nearest = <FileNode>[];
    for (final lyric in _lyrics) {
      final rank = folder.rank(_folders[lyric]);
      final comparison = _compareRank(rank, bestRank);
      if (comparison > 0) {
        bestRank = rank;
        nearest.clear();
      }
      if (_compareRank(rank, bestRank) == 0) nearest.add(lyric);
    }
    return nearest;
  }

  /// 同分的不同文件不按遍历顺序任选一个；同一节点重复出现则合并。
  static FileNode? unique(Iterable<FileNode> candidates) {
    final distinct = {for (final node in candidates) identity(node): node};
    return distinct.length == 1 ? distinct.values.single : null;
  }

  static String identity(FileNode node) {
    final origin = node.fileOrigin;
    if (origin != null) {
      return '${origin.kind.name}:${origin.connectionId}:${origin.filePath}';
    }
    return '${node.source.name}:${node.siteId ?? ''}:'
        '${node.path ?? node.mediaStreamUrl ?? node.hash ?? node.title}';
  }
}

int _compareRank((int, int) a, (int, int) b) {
  final category = a.$1.compareTo(b.$1);
  return category == 0 ? a.$2.compareTo(b.$2) : category;
}

class _MatchFolder {
  _MatchFolder(this.fullPath, this.parts);

  final String fullPath;
  final List<String> parts;

  static _MatchFolder? fromPath(String? path, {String? folder, String? root}) {
    String? directory = folder;
    if (directory == null || directory.isEmpty) {
      if (path == null || path.isEmpty) return null;
      final normalized = _normalize(path);
      if (!normalized.contains('/')) return null; // 哈希不代表目录。
      directory = NodeFolder.dirName(normalized);
    }
    final full = _normalize(directory);
    var relative = full;
    if (root != null && root.isNotEmpty) {
      final normalizedRoot = _normalize(root);
      if (full == normalizedRoot) {
        relative = '';
      } else {
        final prefix = normalizedRoot.endsWith('/')
            ? normalizedRoot
            : '$normalizedRoot/';
        if (full.startsWith(prefix)) relative = full.substring(prefix.length);
      }
    }
    return _MatchFolder(
      full,
      relative.split('/').where((part) => part.isNotEmpty).toList(),
    );
  }

  (int, int) rank(_MatchFolder? other) {
    if (other == null) return (0, 0);
    if (fullPath == other.fullPath) return (4, 0);

    var prefix = 0;
    while (prefix < parts.length &&
        prefix < other.parts.length &&
        parts[prefix] == other.parts[prefix]) {
      prefix++;
    }
    if (prefix > 0 &&
        (prefix == parts.length || prefix == other.parts.length)) {
      return (3, prefix);
    }

    // 独立的音频根目录和字幕根目录也可通过末端的相对层级对应。
    var suffix = 0;
    while (suffix < parts.length &&
        suffix < other.parts.length &&
        parts[parts.length - 1 - suffix] ==
            other.parts[other.parts.length - 1 - suffix]) {
      suffix++;
    }
    if (suffix > 0) return (2, suffix);

    // 支持 A/track.mp3 与 A/字幕/track.srt 等嵌套目录。
    return prefix > 0 ? (1, prefix) : (0, 0);
  }

  static String _normalize(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme && value.contains('://')) {
      // 解码 URI 路径；查询参数、签名和片段不参与目录比较。
      final path = Uri.decodeComponent(uri.path);
      return NodeFolder.normalizePath(
        uri.scheme == 'file' ? path : '${uri.scheme}://${uri.authority}$path',
      );
    }
    return NodeFolder.normalizePath(value);
  }
}
