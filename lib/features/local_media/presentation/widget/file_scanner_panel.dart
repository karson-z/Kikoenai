import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/local_media/presentation/widget/rename_dialog.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import '../../../../core/service/file/file_scanner_service.dart';

class FileBrowserPanel extends ConsumerStatefulWidget {
  // 1. 数据完全由父组件传入
  final List<FileNode> rootNodes;
  final ScanMode scanMode;

  const FileBrowserPanel({
    super.key,
    required this.rootNodes,
    required this.scanMode,
  });

  @override
  ConsumerState<FileBrowserPanel> createState() => _FileBrowserPanelState();
}

class _FileBrowserPanelState extends ConsumerState<FileBrowserPanel> {
  // 2. 组件内部仅维护“浏览路径”这一 UI 状态
  List<FileNode> _breadcrumbs = [];

  @override
  Widget build(BuildContext context) {
    // 3. 根据传入的 rootNodes 和内部的 _breadcrumbs 计算当前显示内容
    final List<FileNode> currentNodes = _breadcrumbs.isEmpty
        ? widget.rootNodes
        : (_breadcrumbs.last.children ?? []);

    return PopScope(
      canPop: _breadcrumbs.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBack();
      },
      child: Column(
        children: [
          // 面包屑
          _buildBreadcrumbBar(),

          const Divider(height: 1),

          // 文件列表
          Expanded(
            child: _buildFileList(
              context,
              currentNodes,
              widget.scanMode, // 使用传入的模式
            ),
          ),
        ],
      ),
    );
  }
  void _enterFolder(FileNode node) {
    setState(() {
      _breadcrumbs.add(node);
    });
  }

  void _navigateBack() {
    if (_breadcrumbs.isNotEmpty) {
      setState(() {
        _breadcrumbs.removeLast();
      });
    }
  }

  void _jumpToBreadcrumb(int index) {
    if (index == -1) {
      setState(() {
        _breadcrumbs.clear();
      });
    } else {
      setState(() {
        _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
      });
    }
  }
  Widget _buildBreadcrumbBar() {
    return Container(
      height: 38,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InkWell(
            onTap: () => _jumpToBreadcrumb(-1),
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.home_outlined,
                  size: 20,
                  color: _breadcrumbs.isEmpty ? Colors.grey : Colors.blue,
                ),
              ),
            ),
          ),
          for (int i = 0; i < _breadcrumbs.length; i++) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => _jumpToBreadcrumb(i),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    _breadcrumbs[i].title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: i == _breadcrumbs.length - 1
                          ? Theme.of(context).colorScheme.onInverseSurface
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<FileNode> nodes, ScanMode scanMode) {
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
          return _buildFolderItem(node);
        } else {
          return _buildFileItem(node, nodes, scanMode);
        }
      },
    );
  }

  Widget _buildFolderItem(FileNode node) {
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
      onTap: () => _enterFolder(node),
    );
  }

  Widget _buildFileItem(FileNode node, List<FileNode> contextNodes, ScanMode scanMode) {
    IconData icon;
    Color iconColor;

    // 根据 scanMode 决定图标
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
          // 这里虽然调用了 ref.read (业务逻辑)，但数据源已经是父组件传入的了
          // 如果想更加彻底的解耦，可以将 onFileTap 作为回调函数传入
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