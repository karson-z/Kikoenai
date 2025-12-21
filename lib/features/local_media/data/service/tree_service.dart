import 'dart:io';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/app_media_item.dart';
// 假设你的 NodeType 枚举在这里，确保它有 subtitle 选项，如果没有就归类为 other
import '../../../../core/enums/node_type.dart';
import '../../../album/data/model/file_node.dart';

class MediaTreeBuilder {
  /// 核心转换方法
  static List<FileNode> build(List<AppMediaItem> flatItems, List<String> rootPaths) {
    List<FileNode> rootNodes = [];

    // 1. 预处理根目录：按长度降序排列
    rootPaths.sort((a, b) => b.length.compareTo(a.length));

    for (var item in flatItems) {
      String? matchedRoot;
      String relativePath = "";

      // [修改点 1] 路径标准化：为了处理 Zip 虚拟路径中的 '/'，统一替换反斜杠
      // 这样无论在 Windows 还是 Unix，也无论是否在压缩包内，都能正确按照层级切割
      final normalizedItemPath = item.path.replaceAll('\\', '/');

      // 2. 找到该文件所属的根目录
      for (var root in rootPaths) {
        // 同样标准化根路径进行匹配
        final normalizedRoot = root.replaceAll('\\', '/');

        if (normalizedItemPath.startsWith(normalizedRoot)) {
          matchedRoot = root; // 保留原始根路径用于显示名称

          // 计算相对路径
          if (normalizedItemPath.length > normalizedRoot.length) {
            relativePath = normalizedItemPath.substring(normalizedRoot.length);
            // 去除开头的分隔符
            if (relativePath.startsWith('/')) {
              relativePath = relativePath.substring(1);
            }
          } else {
            relativePath = "";
          }
          break;
        }
      }

      if (matchedRoot == null) continue;

      // 3. 构建虚拟根目录显示名称 (使用原始路径获取最后一段)
      String rootDisplayName = matchedRoot.split(Platform.pathSeparator).where((e) => e.isNotEmpty).last;

      // 4. [修改点 2] 统一使用 '/' 切割路径
      // 这里的 relativePath 已经是标准化过的（全 '/')
      List<String> parts = [rootDisplayName];
      if (relativePath.isNotEmpty) {
        parts.addAll(relativePath.split('/'));
      }

      // 5. 逐级查找或创建节点
      List<FileNode> currentLevel = rootNodes;
      String currentAbsolutePath = matchedRoot; // 这里的路径拼接仅用于生成 ID 或层级追踪

      for (int i = 0; i < parts.length; i++) {
        String partName = parts[i];
        bool isLast = i == parts.length - 1;

        // 更新当前层级的绝对路径
        if (i > 0) {
          currentAbsolutePath = "$currentAbsolutePath/$partName";
        }

        if (isLast) {
          // --- 是文件 (叶子节点) ---
          currentLevel.add(FileNode(
            type: _mapType(item), // [修改点 3] 调用更新后的类型映射
            title: partName,
            hash: item.path.hashCode.toString(),
            workTitle: item.album,
            mediaStreamUrl: item.path, // 这里的 path 包含了压缩包虚拟路径
            duration: item.durationSeconds,
            artist: item.artist,
            size: 0, // 如果需要大小，可以在 AppMediaItem 中补充
          ));
        } else {
          // --- 是文件夹 (或压缩包) ---
          // 逻辑说明：如果路径是 A/B.zip/C.srt
          // 当处理到 B.zip 时，isLast=false，它会被自动视为文件夹节点创建

          FileNode? folderNode;
          try {
            folderNode = currentLevel.firstWhere(
                    (n) => n.isFolder && n.title == partName
            );
          } catch (e) {
            folderNode = null;
          }

          if (folderNode == null) {
            folderNode = FileNode(
              type: NodeType.folder,
              title: partName,
              hash: currentAbsolutePath.hashCode.toString(),
              // 如果是第一级，路径就是根目录，否则拼接
              mediaStreamUrl: (i == 0) ? matchedRoot : currentAbsolutePath,
              children: [],
            );
            currentLevel.add(folderNode);
          }

          currentLevel = folderNode.children!;
        }
      }
    }

    // 6. 全局排序
    _sortRecursive(rootNodes);

    return rootNodes;
  }

  // 递归排序辅助方法
  static void _sortRecursive(List<FileNode> nodes) {
    nodes.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    for (var node in nodes) {
      if (node.isFolder && node.children != null) {
        _sortRecursive(node.children!);
      }
    }
  }

  // [修改点 4] 类型映射辅助：增加字幕支持
  static NodeType _mapType(AppMediaItem item) {
    if (!item.path.contains('.')) return NodeType.other;

    // 加上 "." 并且转小写
    final ext = ".${item.path.split('.').last.toLowerCase()}";

    if (FileExtensions.audio.contains(ext)) return NodeType.audio;
    if (FileExtensions.video.contains(ext)) return NodeType.video;

    // 如果 FileExtensions 里有 subtitles 集合
    if (FileExtensions.subtitles.contains(ext)) {

      return NodeType.text;
    }

    return NodeType.other;
  }
}