import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/local_media/presentation/widget/status_pill.dart';

import '../../../../core/constants/app_file_extensions.dart';
import '../../../../core/model/file_node.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../player/presentation/provider/player_controller_provider.dart';
import '../provider/file_scanner_notifier.dart';
import 'file_operation_sheet.dart';

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
    final scannerState = ref.watch(fileScannerProvider);
    final scannerNotifier = ref.read(fileScannerProvider.notifier);

    final List<FileNode> currentNodes = scannerState.children;

    return PopScope(
      canPop: scannerState.isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        scannerNotifier.stepOut();
      },
      child: _buildFileList(context, ref, currentNodes, scanMode),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    List<FileNode> nodes,
    ScanMode scanMode,
  ) {
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

    final itemCount = node.subItemsCount;
    final itemCountText = "$itemCount 项";

    final subtitleText = node.workId != null
        ? "RJ0${node.workId}  •  $itemCountText"
        : itemCountText;

    return ListTile(
      leading: Icon(
        isArchiveFolder ? Icons.folder_zip : Icons.folder,
        color: isArchiveFolder ? Colors.purpleAccent : Colors.amber,
      ),
      title: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitleText,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NodeStatusPill(status: node.nodeStatus),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onLongPress: () => FolderActionBottomSheet.show(context, node),
      onTap: () {
        if (node.path != null) {
          ref.read(fileScannerProvider.notifier).stepIn(NodeFolder(node.path!));
        }
      },
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
    List<FileNode> contextNodes,
    ScanMode scanMode,
  ) {
    IconData icon;
    Color iconColor;

    final fileType = FileExtensions.getFileType(node.title);

    switch (fileType) {
      case FileType.audio:
        icon = Icons.audiotrack;
        iconColor = Colors.blue;
        break;
      case FileType.video:
        icon = Icons.videocam;
        iconColor = Colors.orange;
        break;
      case FileType.subtitle:
        icon = Icons.subtitles;
        iconColor = Colors.teal;
        break;
      case FileType.image:
        icon = Icons.image;
        iconColor = Colors.purple;
        break;
      case FileType.archive:
        icon = Icons.folder_zip;
        iconColor = Colors.brown;
        break;
      case FileType.document:
        icon = Icons.description;
        iconColor = Colors.blueGrey;
        break;
      case FileType.unknown:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
        break;
    }
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        node.mediaStreamUrl ?? "",
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onLongPress: () => FolderActionBottomSheet.show(context, node),
      onTap: () {
        if (scanMode == ScanMode.subtitles) {
          Clipboard.setData(
            ClipboardData(text: node.mediaStreamUrl ?? node.hash ?? ""),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("已复制路径: ${node.title}"),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final workId = node.workId;
          Work? work;
          if (workId != null) {
            work = ScraperStorage().getWork(workId);
          }

          ref
              .read(playerControllerProvider.notifier)
              .handleFileTap(
                node,
                contextNodes,
                work: work,
                source: workId == null
                    ? NodeSource.localSingle
                    : NodeSource.localWork,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("开始播放: ${node.title}"),
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
