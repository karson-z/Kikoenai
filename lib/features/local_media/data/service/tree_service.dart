import 'dart:io';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/app_media_item.dart';
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
      String relativePath = item.path;

      // 2. 找到该文件所属的根目录
      for (var root in rootPaths) {
        if (item.path.startsWith(root)) {
          matchedRoot = root;

          // 去掉前缀，得到相对路径
          if (item.path.length > root.length) {
            relativePath = item.path.substring(root.length);
            if (relativePath.startsWith(Platform.pathSeparator)) {
              relativePath = relativePath.substring(1);
            }
          } else {
            relativePath = "";
          }
          break;
        }
      }

      if (matchedRoot == null) continue;

      // 3. 构建虚拟根目录显示名称
      String rootDisplayName = matchedRoot.split(Platform.pathSeparator).where((e) => e.isNotEmpty).last;

      // 4. 将 "虚拟根名" 拼接到路径切片中
      List<String> parts = [rootDisplayName];
      if (relativePath.isNotEmpty) {
        parts.addAll(relativePath.split(Platform.pathSeparator));
      }

      // 5. 逐级查找或创建节点
      List<FileNode> currentLevel = rootNodes;
      String currentAbsolutePath = matchedRoot;

      for (int i = 0; i < parts.length; i++) {
        String partName = parts[i];
        bool isLast = i == parts.length - 1;

        // 更新当前层级的绝对路径
        if (i > 0) {
          currentAbsolutePath = "$currentAbsolutePath${Platform.pathSeparator}$partName";
        }

        if (isLast) {
          // --- 是文件 (叶子节点) ---
          currentLevel.add(FileNode(
            type: _mapType(item),
            title: partName,
            // 【修改点】：使用文件绝对路径的 hashCode 作为唯一 ID
            hash: item.path.hashCode.toString(),
            workTitle: item.album,
            mediaStreamUrl: item.path,
            duration: item.durationSeconds,
            artist: item.artist,
            size: 0,
          ));
        } else {
          // --- 是文件夹 ---
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
              // 【建议】：文件夹也加上 ID，使用文件夹路径的 hashCode
              hash: currentAbsolutePath.hashCode.toString(),
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

  // 类型映射辅助
  static NodeType _mapType(AppMediaItem item) {
    // 1. 安全检查
    if (!item.path.contains('.')) return NodeType.other;

    final ext = ".${item.path.split('.').last.toLowerCase()}";

    // 3. 匹配
    if (FileExtensions.audio.contains(ext)) return NodeType.audio;
    if (FileExtensions.video.contains(ext)) return NodeType.video;

    return NodeType.other;
  }
}