import 'package:flutter/material.dart';

import '../../../album/data/model/file_node.dart';

// import 'path/to/media_node.dart';

class MediaNodeTile extends StatelessWidget {
  final FileNode node;
  final int level; // 缩进层级
  final Function(FileNode)? onPlay; // 点击播放回调

  const MediaNodeTile({
    super.key,
    required this.node,
    this.level = 0,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 如果是文件 -> ListTile
    if (!node.isFolder) {
      return ListTile(
        // 利用 contentPadding 做物理缩进，比 Padding Widget 性能好点
        contentPadding: EdgeInsets.only(left: 16.0 + (level * 16), right: 16),
        dense: true,
        leading: Icon(
          node.isAudio ? Icons.movie_creation_outlined : Icons.music_note,
          color: node.isAudio ? Colors.orange : Colors.blueAccent,
          size: 20,
        ),
        title: Text(
          node.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: node.duration != null && node.duration! > 0
            ? Text(
            _formatDuration(node.duration!),
            style: const TextStyle(fontSize: 11, color: Colors.grey)
        )
            : null,
        onTap: () {
          if (onPlay != null) onPlay!(node);
        },
      );
    }

    // 2. 如果是文件夹 -> ExpansionTile (递归入口)
    return Theme(
      // 消除 ExpansionTile 展开时的上下边框线
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: 16.0 + (level * 16), right: 16),
        leading: const Icon(Icons.folder_open, color: Colors.amber),
        title: Text(
            node.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
        ),
        subtitle: Text(
          "${node.children?.length ?? 0} 项",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        // --- 核心递归 ---
        children: (node.children ?? []).map((childNode) {
          return MediaNodeTile(
            node: childNode,
            level: level + 1, // 层级 +1
            onPlay: onPlay,
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final int min = seconds ~/ 60;
    final int sec = (seconds % 60).toInt();
    return "$min:${sec.toString().padLeft(2, '0')}";
  }
}