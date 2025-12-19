// file_browser_panel.dart
import 'package:extended_image/extended_image.dart' as ref;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/player/provider/player_controller_provider.dart';
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

// --- 子组件：面包屑导航条 ---
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
          // 根目录图标
          InkWell(
            onTap: () => onItemTap(-1),
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.home_outlined,
                    size: 20,
                    color: pathStack.isEmpty ? Colors.grey : Colors.blue
                ),
              ),
            ),
          ),

          // 路径节点
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
                      // 当前层级黑色，之前的层级蓝色
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

// --- 子组件：文件列表 ---
class _FileList extends ConsumerWidget {
  final FileScannerState state;
  final FileScannerNotifier notifier;

  const _FileList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 扫描中且无数据
    if (state.isScanning && state.treeRoot.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. 获取当前视图数据 (利用 State 中的 Getter)
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
          return ListTile(
            leading: const Icon(Icons.folder, color: Colors.amber),
            title: Text(node.title),
            subtitle: Text("${node.children?.length ?? 0} 项"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => notifier.enterFolder(node.title),
          );
        } else {
          return ListTile(
            leading: Icon(
              node.isAudio ? Icons.audiotrack : Icons.movie,
              color: node.isAudio ? Colors.blue : Colors.orange,
            ),
            title: Text(node.title),
            subtitle: node.duration != null
                ? Text(_formatDuration(node.duration!))
                : null,
            onTap: () {
              debugPrint("点击了: ${node.toJson()}");
              debugPrint("当前层级：${currentNodes.toString()}");
              final playerController = ref.read(playerControllerProvider.notifier);
              playerController.handleFileTap(node, currentNodes);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("播放: ${node.title}"),
                    duration: const Duration(milliseconds: 500),
                  )
              );
            },
          );
        }
      },
    );
  }

  String _formatDuration(double seconds) {
    final int min = seconds ~/ 60;
    final int sec = (seconds % 60).toInt();
    return "$min:${sec.toString().padLeft(2, '0')}";
  }
}