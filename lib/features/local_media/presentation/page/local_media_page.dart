import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_worker.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import '../../../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/utils/scraper/scraper_controller.dart';
import '../../../../core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import '../../data/model/file_scanner_state.dart';
import '../provider/file_scanner_notifier.dart';
import '../widget/file_scanner_panel.dart';
import '../widget/parsed_works_view.dart';
import '../widget/path_sheet.dart';
import '../../../../../../core/model/file_node.dart';
import '../../../../../../core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';
import '../widget/scraper_drawer.dart';

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(fileScannerProvider);
    final queueState = ref.watch(scraperQueueProvider);

    final isScanning = scannerState.status == WorkerState.scanning;
    final currentMode = scannerState.scanMode;
    // 1. 获取全局的面包屑数据和控制器
    final breadcrumbs = ref.watch(breadcrumbProvider);
    final breadcrumbNotifier = ref.read(breadcrumbProvider.notifier);

    final queueCount = queueState.pending.length + queueState.processing.length;

    ref.listen<FileScannerState>(fileScannerProvider, (previous, next) {
      final wasScanning = previous?.status == WorkerState.scanning;
      final isNowIdle = next.status == WorkerState.idle || next.status == WorkerState.done;
      if (wasScanning && isNowIdle) {
        final pendingNodes = _extractPendingNodes(next.roots);
        if (pendingNodes.isNotEmpty) {
          _showScanCompleteDialog(context, ref, pendingNodes);
        }
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 66,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '媒体库',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(scannerState.status, scannerState.scannedCount),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isScanning
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return  Padding(padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: '解析队列',
                    icon: Badge(
                      isLabelVisible: queueCount > 0,
                      label: Text(queueCount.toString()),
                      child: const Icon(Icons.swap_vert_circle_outlined),
                    ),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  ),
                );
              },
            ),
          ],
        ),
        endDrawer: const ScraperQueueDrawer(),
        body: Column(
          children: [
            // 1. 固定在顶部的控制栏（面包屑 + 药丸 TabBar）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Expanded(
                    child: BreadcrumbBar(
                      // 提取标题集合
                      paths: breadcrumbs.map((node) => node.title).toList(),
                      // 绑定点击根目录事件
                      onHomeTap: () => breadcrumbNotifier.jumpTo(-1),
                      // 绑定点击具体层级事件
                      onPathTap: (index) => breadcrumbNotifier.jumpTo(index),

                      // 可选：在此处覆盖默认样式
                      // backgroundColor: Colors.transparent,
                    ),// 左侧：面包屑无限延伸
                  ),
                  const SizedBox(width: 12),
                  // 右侧：药丸 TabBar
                  Container(
                    width: 150,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontSize: 13),
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        tabs: const [
                          Tab(text: "待解析"),
                          Tab(text: "已解析"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPendingView(context, scannerState, currentMode),
                  ParseWorksView(work: ScraperStorage().getAllWorks()),
                ],
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.folder_copy_outlined),
          label: const Text("管理路径"),
          onPressed: () {
            PathManagerSheet.show(context);
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildPendingView(BuildContext context, scannerState, ScanMode currentMode) {
    if (scannerState.roots.isEmpty) {
      return _buildEmptyStateView(context);
    }
    return FileBrowserPanel(
      rootNodes: scannerState.roots,
      scanMode: currentMode,
    );
  }

  String _getStatusText(WorkerState status, int count) {
    switch (status) {
      case WorkerState.idle:
        return count > 0 ? '共 $count 个文件' : '准备就绪';
      case WorkerState.scanning:
        return '正在扫描中... ($count)';
      case WorkerState.done:
        return '扫描完成，共 $count 个文件';
      case WorkerState.error:
        return '扫描出错，请重试';
    }
  }

  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.surfaceTint,
          ),
          const SizedBox(height: 16),
          Text(
            "这里空空如也",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            "点击下方按钮管理文件夹",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              PathManagerSheet.show(context);
            },
            icon: const Icon(Icons.add),
            label: const Text("添加文件夹"),
          ),
        ],
      ),
    );
  }

  List<FileNode> _extractPendingNodes(List<FileNode> nodes) {
    final pendingNodes = <FileNode>[];
    void findPending(List<FileNode> currentLevel) {
      for (var node in currentLevel) {
        if (node.nodeStatus == NodeStatus.pending && node.rjCode != null) {
          pendingNodes.add(node);
        }
        if (node.isFolder && node.children != null) {
          findPending(node.children!);
        }
      }
    }
    findPending(nodes);
    return pendingNodes;
  }

  void _showScanCompleteDialog(BuildContext context, WidgetRef ref, List<FileNode> pendingNodes) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('扫描完成'),
          content: Text('一共扫描到待解析作品共 ${pendingNodes.length} 个，是否全部加入解析队列并开始解析？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('暂不'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(scraperQueueProvider.notifier).addTasks(pendingNodes);
                ref.read(scraperQueueProvider.notifier).start();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已全部加入后台队列并开始解析')),
                );
              },
              child: const Text('一键加入并开始'),
            ),
          ],
        );
      },
    );
  }
}