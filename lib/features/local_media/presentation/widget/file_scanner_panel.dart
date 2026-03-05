import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/local_media/presentation/widget/rename_dialog.dart';
import '../../../../core/constants/app_file_extensions.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';
import '../../../../core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import '../../../../core/model/file_node.dart';
import '../../../player/presentation/provider/player_controller_provider.dart';

class FileBrowserPanel extends ConsumerWidget {
  final List<FileNode> rootNodes;
  final ScanMode scanMode;

  const FileBrowserPanel({
    super.key,
    required this.rootNodes,
    required this.scanMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听面包屑状态
    final breadcrumbs = ref.watch(breadcrumbProvider);

    // 计算当前需要显示的节点
    final List<FileNode> currentNodes = breadcrumbs.isEmpty
        ? rootNodes
        : (breadcrumbs.last.children ?? []);

    return PopScope(
      canPop: breadcrumbs.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 拦截物理返回键，执行返回上一级逻辑
        ref.read(breadcrumbProvider.notifier).navigateBack();
      },
      child: Column(
        children: [
          // 面包屑导航栏
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: BreadcrumbBar(),
          ),

          const Divider(height: 1),

          // 文件列表
          Expanded(
            child: _buildFileList(context, ref, currentNodes, scanMode),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, WidgetRef ref, List<FileNode> nodes, ScanMode scanMode) {
    if (nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text("空文件夹", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        if (node.isFolder) {
          return _buildFolderItem(context, ref, node);
        } else {
          return _buildFileItem(context, ref, node, nodes, scanMode);
        }
      },
    );
  }

  Widget _buildFolderItem(BuildContext context, WidgetRef ref, FileNode node) {
    final isArchiveFolder = FileExtensions.isArchive(node.title);

    return ListTile(
      leading: Icon(
        isArchiveFolder ? Icons.folder_zip : Icons.folder,
        color: isArchiveFolder ? Colors.purpleAccent : Colors.amber,
      ),
      title: Text(node.title),
      subtitle: Text(
        "${node.children?.length ?? 0} 项",
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onLongPress: () => RenameFileDialog.show(context, node),
      onTap: () {
        // 使用 Provider 的逻辑进入文件夹
        ref.read(breadcrumbProvider.notifier).enterFolder(node);
      },
    );
  }

  Widget _buildFileItem(BuildContext context, WidgetRef ref, FileNode node, List<FileNode> contextNodes, ScanMode scanMode) {
    IconData icon;
    Color iconColor;

    switch (scanMode) {
      case ScanMode.audio:
        icon = Icons.audiotrack;
        iconColor = Colors.blue;
        break;
      case ScanMode.video:
        icon = Icons.videocam;
        iconColor = Colors.orange;
        break;
      case ScanMode.subtitles:
        icon = Icons.subtitles;
        iconColor = Colors.teal;
        break;
    }

    Widget? subtitleWidget;
    if (scanMode != ScanMode.subtitles) {
      if (node.duration != null && node.duration! > 0) {
        subtitleWidget = Text(_formatDuration(node.duration!));
      }
    } else {
      subtitleWidget = Text(
        node.mediaStreamUrl ?? "",
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleWidget,
      onLongPress: () => RenameFileDialog.show(context, node),
      onTap: () {
        if (scanMode == ScanMode.subtitles) {
          Clipboard.setData(ClipboardData(text: node.mediaStreamUrl ?? node.hash ?? ""));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("已复制路径: ${node.title}"),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              )
          );
        } else {
          ref.read(playerControllerProvider.notifier).handleFileTap(node, contextNodes);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("开始播放: ${node.title}"),
                duration: const Duration(milliseconds: 500),
                behavior: SnackBarBehavior.floating,
              )
          );
        }
      },
    );
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return "";
    final int min = seconds ~/ 60;
    final int sec = (seconds % 60).toInt();
    return "$min:${sec.toString().padLeft(2, '0')}";
  }
}