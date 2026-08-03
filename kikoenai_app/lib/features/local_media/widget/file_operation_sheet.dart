import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'rename_dialog.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';

class FolderActionBottomSheet extends ConsumerWidget {
  final FileNode node;

  const FolderActionBottomSheet({super.key, required this.node});

  static Future<void> show(BuildContext context, FileNode node) {
    return KikoenaiDialog.showBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FolderActionBottomSheet(node: node),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 尝试从本地数据库获取该作品的详细信息
    Work? work;
    if (node.workId != null) {
      work = ScraperStorage().getWork(node.workId!);
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部小把手
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. 头部信息区域 (完美复刻截图样式)
          _buildHeader(context, work),

          const Divider(height: 1),

          // 3. 操作列表
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                _buildActionTile(
                  context: context,
                  icon: Icons.copy,
                  title: "复制当前路径",
                  subtitle: node.mediaStreamUrl,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(
                      ClipboardData(text: node.mediaStreamUrl ?? ""),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("已复制路径: ${node.title}")),
                    );
                    },
                ),
                _buildActionTile(
                  context: context,
                  icon: Icons.drive_file_rename_outline,
                  title: "重命名",
                  subtitle: "修改本地文件夹名称",
                  onTap: () {
                    Navigator.pop(context);
                    RenameFileDialog.show(context, node);
                  },
                ),
                _buildActionTile(
                  context: context,
                  icon: Icons.queue_play_next,
                  title: "加入解析队列",
                  subtitle: "手动将此文件夹加入后台元数据刮削",
                  onTap: () {
                    Navigator.pop(context);
                    if (node.workId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("未检测到有效 RJ 码，无法解析")),
                      );
                      return;
                    }
                    // 将节点加入爬虫队列并直接启动
                    ref.read(scraperQueueProvider.notifier).addTasks([node]);
                    ref.read(scraperQueueProvider.notifier).start();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("已将 RJ0${node.workId} 加入解析队列")),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // 底部留白
        ],
      ),
    );
  }

  /// 构建头部 UI（图片 + 标题 + 副标题）
  Widget _buildHeader(BuildContext context, Work? work) {
    // 如果没有解析数据，使用节点自身的标题作为占位
    final String title = work?.title ?? node.title;
    // 副标题：优先使用社团名(name)，其次 RJ码，最后是保底文本
    final String subtitle = work?.name ?? (node.workId == null ? null : 'RJ0${node.workId}') ?? '本地文件夹';
    // 封面图
    final String? imageUrl = work?.thumbnailCoverUrl ?? work?.mainCoverUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 封面图片 / 默认文件夹图标
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl != null
                ? SimpleExtendedImage(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : _buildFallbackIcon(context),
          ),
          const SizedBox(width: 12),
          // 文本信息区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 默认占位图标
  Widget _buildFallbackIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        FileExtensions.isArchive(node.title) ? Icons.folder_zip : Icons.folder,
        color: FileExtensions.isArchive(node.title)
            ? Colors.purpleAccent
            : Colors.amber,
      ),
    );
  }

  /// 封装列表项，统一风格（带图标、主标题、副标题）
  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
    );
  }
}
