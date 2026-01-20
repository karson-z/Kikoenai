import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/local_media/presentation/widget/rename_dialog.dart';

import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../../album/data/model/file_node.dart';
import '../../data/model/file_scanner_state.dart';
import '../provider/file_scanner_provider.dart';

class FileBrowserPanel extends ConsumerWidget {
  const FileBrowserPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听状态
    final scannerState = ref.watch(fileScannerProvider);
    final notifier = ref.read(fileScannerProvider.notifier);

    // 拦截返回键逻辑
    return PopScope(
      canPop: scannerState.pathStack.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        notifier.navigateBack();
      },
      child: Column(
        children: [
          // 2. 面包屑导航
          _BreadcrumbBar(
            pathStack: scannerState.pathStack,
            onItemTap: notifier.jumpToPathIndex,
          ),

          const Divider(height: 1),

          // 3. 文件列表区
          Expanded(
            child: _FileList(
              state: scannerState,
              notifier: notifier,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 子组件：面包屑导航条 (保持不变) ---
class _BreadcrumbBar extends StatelessWidget {
  final List<String> pathStack;
  final Function(int) onItemTap;

  const _BreadcrumbBar({
    required this.pathStack,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InkWell(
            onTap: () => onItemTap(-1),
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.home_outlined,
                    size: 20,
                    color: pathStack.isEmpty ? Colors.grey : Colors.blue),
              ),
            ),
          ),
          for (int i = 0; i < pathStack.length; i++) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => onItemTap(i),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    pathStack[i],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: i == pathStack.length - 1
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
}

// --- 子组件：文件列表 (重点修改) ---
class _FileList extends ConsumerWidget {
  final FileScannerState state;
  final FileScannerNotifier notifier;

  const _FileList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isScanning && state.treeRoot.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. 获取当前视图数据
    final currentNodes = state.currentViewNodes;

    // 3. 空文件夹
    if (currentNodes.isEmpty) {
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

    // 4. 列表渲染
    return ListView.builder(
      itemCount: currentNodes.length,
      itemBuilder: (context, index) {
        final node = currentNodes[index];

        if (node.isFolder) {
          return _buildFolderItem(context, node);
        } else {
          return _buildFileItem(context, ref, node, currentNodes);
        }
      },
    );
  }

  // --- 抽取：构建文件夹/压缩包 Item ---
  Widget _buildFolderItem(BuildContext context, FileNode node) {
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

      // [修复] 添加长按事件！
      onLongPress: () {
        RenameFileDialog.show(context, node);
      },

      onTap: () => notifier.enterFolder(node.title),
    );
  }

  // --- 抽取：构建普通文件 Item ---
  Widget _buildFileItem(
      BuildContext context,
      WidgetRef ref,
      FileNode node,
      List<FileNode> currentNodes
      ) {
    // 1. 准备图标和颜色
    IconData icon;
    Color iconColor;

    switch (state.scanMode) {
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

    // 2. 准备副标题 (时长 或 路径)
    Widget? subtitleWidget;
    if (state.scanMode != ScanMode.subtitles) {
      // 音视频显示时长
      if (node.duration != null && node.duration! > 0) {
        subtitleWidget = Text(_formatDuration(node.duration!));
      }
    } else {
      // 字幕显示路径 (防止溢出)
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

      // [新增] 长按重命名 (直接调用封装好的组件)
      onLongPress: () {
        RenameFileDialog.show(context, node);
      },

      onTap: () {
        if (state.scanMode == ScanMode.subtitles) {

          Clipboard.setData(ClipboardData(text: node.mediaStreamUrl ?? node.hash!));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("已复制路径: ${node.title}"),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              )
          );
        } else {
          final playerController = ref.read(playerControllerProvider.notifier);
          playerController.handleFileTap(node, currentNodes);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("开始播放: ${node.title}"),
                duration: const Duration(milliseconds: 500),
                behavior: SnackBarBehavior.floating, // 悬浮样式体验更好
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