import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/features/local_media/data/model/file_scanner_state.dart';
import '../../../../core/utils/scraper/scraper_controller.dart';
import '../../../../core/utils/scraper/scraper_storage.dart';
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
    // 1. 订阅最新的由对象驱动的单层切片文件树状态
    final scannerState = ref.watch(fileScannerProvider);
    final scannerNotifier = ref.read(fileScannerProvider.notifier);

    final queueState = ref.watch(scraperQueueProvider);
    final currentMode = scannerState.scanMode;
    final queueCount = queueState.pending.length + queueState.processing.length;
    final root = scannerState.rootPath;

    List<String> breadcrumbPaths = scannerState.breadcrumbPaths;

    // 3. 监听扫描流异步完成的副作用（仅在扫描状态由 true 变为 false 且存在有效节点时触发弹窗）
    ref.listen<FileBrowserState>(fileScannerProvider, (previous, next) {
      final wasScanning = previous?.isScanning ?? false;
      final isNowDone = !next.isScanning;

      if (wasScanning &&
          isNowDone &&
          scannerNotifier.didLastResultCompleteSync &&
          next.rootPath.isNotEmpty) {
        final pendingNodes = scannerNotifier.getPendingWorkNodesInActiveRoot();
        if (pendingNodes.isNotEmpty && next.scanMode != ScanMode.subtitles) {
          _showScanCompleteDialog(context, ref, pendingNodes);
        }
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 66,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '媒体库',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '同步媒体库',
                        icon: scannerState.isScanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        onPressed:
                            scannerState.rootPath.isEmpty ||
                                scannerState.isScanning
                            ? null
                            : () => scannerNotifier.refreshCurrentTarget(),
                      ),
                      IconButton(
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
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        endDrawer: const ScraperQueueDrawer(),
        body: Column(
          children: [
            // 固定在顶部的控制栏（面包屑导航 + 药丸式切换 TabBar）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: root.isEmpty
                        ? const SizedBox.shrink()
                        : BreadcrumbBar(
                            paths: breadcrumbPaths,
                            // 点击 Home 图标：直接移回根目录
                            onHomeTap: () => scannerNotifier.goHome(),
                            // 点击中间具体的任意面包屑节点：执行绝对路径链式计算并瞬移跳转
                            onPathTap: (index) {
                              String targetAbsolutePath = root;
                              for (int k = 0; k <= index; k++) {
                                targetAbsolutePath =
                                    '$targetAbsolutePath/${breadcrumbPaths[k]}';
                              }
                              scannerNotifier.jumpToPath(targetAbsolutePath);
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  // 右侧：“待解析 / 已解析”切换小药丸
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
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 13),
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
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

  Widget _buildPendingView(
    BuildContext context,
    FileBrowserState scannerState,
    ScanMode currentMode,
  ) {
    if (scannerState.rootPath.isEmpty) {
      return _buildEmptyStateView(context);
    }

    return FileBrowserPanel(
      rootNodes: scannerState.children, // 对齐模型字段，投喂当前层级下已被索引转换好的直接子节点列表
      scanMode: currentMode,
    );
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
          Text("这里空空如也", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "点击下方按钮管理并添加文件夹",
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

  void _showScanCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    List<FileNode> pendingNodes,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('扫描完成'),
          content: Text(
            '一共扫描到待解析作品共 ${pendingNodes.length} 个，是否全部加入解析队列并开始解析？',
          ),
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已全部加入后台队列并开始解析')));
              },
              child: const Text('一键加入并开始'),
            ),
          ],
        );
      },
    );
  }
}
