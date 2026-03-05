import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'work_card.dart'; // 你之前的 WorkCard 组件

class FileToWorkAdapter extends StatelessWidget {
  final FileNode fileNode;

  const FileToWorkAdapter({super.key, required this.fileNode});

  @override
  Widget build(BuildContext context) {
    // 1. 尝试从 FileNode 中获取 RJ 号 (workTitle 字段在 Worker 中被赋值为 RJ 号)
    final String? rjCode = fileNode.workTitle; // 假设 worker 扫描时把 RJ 号存这里了

    // 2. 如果不是作品文件夹 (没有 RJ 号)，显示普通文件夹样式
    if (rjCode == null || rjCode.isEmpty) {
      return _buildNormalFolderCard(context);
    }

    // 3. 如果是作品，监听 Hive 数据库的变化
    // 假设你的 Work 存储在名为 'works' 的 Box 中，Key 是 RJ 号
    return ValueListenableBuilder(
      valueListenable: Hive.box<Work>('works').listenable(keys: [rjCode]),
      builder: (context, Box<Work> box, _) {
        // A. 尝试从数据库获取完整的 Work 信息
        Work? fullWork = box.get(rjCode);

        // B. 如果数据库没数据（还没爬取），用 FileNode 临时构造一个“残缺”的 Work
        // 这样 WorkCard 就能显示出“初始态”（色块占位图 + 文件夹名）
        final displayWork = fullWork ?? Work(
          id: int.tryParse(rjCode.replaceFirst('RJ', '')) ?? 0,
          title: fileNode.title, // 暂时用文件夹名做标题
          mainCoverUrl: null,    // 没封面，WorkCard 会自动显示占位图
          // 其他字段留空...
        );

        // C. 渲染通用的 WorkCard
        return WorkCard(work: displayWork);
      },
    );
  }

  /// 普通文件夹的样式 (非 RJ 作品)
  Widget _buildNormalFolderCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: InkWell(
        onTap: () {
          // TODO: 点击进入下一级目录
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 40, color: Colors.amber),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                fileNode.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}