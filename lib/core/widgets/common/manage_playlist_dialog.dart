import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:kikoenai/core/utils/data/other.dart';

import '../../../features/album/data/model/work.dart';
import '../../../features/download/presentation/provider/download_provider.dart';
import '../../../features/player/presentation/provider/player_controller_provider.dart';
import '../../service/download/download_service.dart';
import '../bread_crumb_bar/file_bread_crumb_bar.dart';
import '../../model/file_node.dart';
import '../../../features/album/presentation/viewmodel/provider/file_manage_provider.dart';

import '../../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../bread_crumb_bar/provider/file_bread_crumb_bar.dart';
import '../layout/app_toast.dart';
import 'back_button_interceptor.dart';

class FileTreeWoltSheet {
  // ==========================================
  // 模式一：作为独立弹窗直接唤起
  // ==========================================
  static Future<void> show({
    required BuildContext context,
    required List<FileNode> roots,
    Work? work,
  }) async {
    await WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: (_) {
        final width = MediaQuery.of(context).size.width;
        return width < 500
            ? const CustomBottomType()
            : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) {
        return [buildPage(modalContext, roots: roots, work: work)];
      },
    );
  }

  static SliverWoltModalSheetPage buildPage(
    BuildContext context, {
    required List<FileNode> roots,
    required Work? work,
  }) {
    return SliverWoltModalSheetPage(
      navBarHeight: 110,
      isTopBarLayerAlwaysVisible: true,
      hasSabGradient: false,
      leadingNavBarWidget: FileTreeStickyHeader(roots: roots, work: work),
      // topBar:
      stickyActionBar: _buildInternalActionBar(roots, work),
      mainContentSliversBuilder: (modalContext) => [
        const SliverPadding(padding: EdgeInsets.only(top: 16)),
        _SliverFileTreeContent(roots: roots, work: work),

        const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
      ],
    );
  }

  /// 内部业务逻辑：下载操作
  static Widget _buildInternalActionBar(List<FileNode> roots, Work? work) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        // 监听选中列表
        final selectedList = ref.watch(fileSelectionProvider.select((s) => s));
        // 监听已下载 ID 集合
        final downloadedIds = ref
            .watch(completedTasksProvider)
            .map((t) => t.task.taskId)
            .toSet();

        final bool canDownload = selectedList.any(
          (node) => !node.isFolder && !downloadedIds.contains(node.hash),
        );

        return Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !canDownload
                        ? null
                        : () {
                            final filesToDownload = selectedList
                                .where(
                                  (node) =>
                                      !node.isFolder &&
                                      !downloadedIds.contains(node.hash),
                                )
                                .toList();

                            DownloadService.instance.enqueueBatch(
                              selectedFiles: filesToDownload,
                              rootNodes: roots,
                              title: work?.title ?? '未知作品',
                              metaData: work?.toJson(),
                            );

                            KikoenaiToast.success("已加入下载队列");
                            Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('下载'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliverFileTreeContent extends ConsumerStatefulWidget {
  final List<FileNode> roots;
  final Work? work;

  const _SliverFileTreeContent({required this.roots, this.work});

  @override
  ConsumerState<_SliverFileTreeContent> createState() => _SliverFileTreeContentState();
}

class _SliverFileTreeContentState extends ConsumerState<_SliverFileTreeContent> {
  Icon _getIconForNode(FileNode node) {
    if (node.isFolder) return const Icon(Icons.folder, color: Colors.amber);
    if (node.isAudio) return const Icon(Icons.audiotrack, color: Colors.purpleAccent);
    if (node.isImage) return const Icon(Icons.image, color: Colors.blue);
    if (node.isVideo) return const Icon(Icons.videocam, color: Colors.redAccent);
    if (node.isText) return const Icon(Icons.description, color: Colors.grey);
    return const Icon(Icons.insert_drive_file, color: Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fileSelectionProvider);
    final breadcrumbs = ref.watch(breadcrumbProvider(BreadCrumbBarType.player));

    // 核心修复：根据面包屑计算当前需要显示的节点列表
    final List<FileNode> currentNodes = breadcrumbs.isEmpty
        ? widget.roots
        : (breadcrumbs.last.children ?? []);

    return SliverMainAxisGroup(
      slivers: [
        if (currentNodes.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text("空文件夹")),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildNodeItem(currentNodes[index]), // 使用 currentNodes
              childCount: currentNodes.length, // 使用 currentNodes.length
            ),
          ),
        const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),
      ],
    );
  }

  Widget _buildNodeItem(FileNode node) {
    final downloadedIds = ref.watch(completedTasksProvider).map((t) => t.task.taskId).toSet();
    final bool isDownloaded = !node.isFolder && downloadedIds.contains(node.hash);
    final bool? checkboxState = ref.read(fileSelectionProvider.notifier).getNodeState(node);

    return InkWell(
      onTap: () {
        if (node.isFolder) {
          // 点击文件夹，触发 Provider 更新状态
          ref.read(breadcrumbProvider(BreadCrumbBarType.player).notifier).enterFolder(node);
        } else {
          ref.read(fileSelectionProvider.notifier).toggleNode(node);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              tristate: true,
              value: checkboxState,
              onChanged: (_) => ref.read(fileSelectionProvider.notifier).toggleNode(node),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            _getIconForNode(node),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          node.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: node.isFolder ? FontWeight.w500 : FontWeight.normal,
                            color: isDownloaded ? Colors.grey.shade600 : null,
                          ),
                        ),
                      ),
                      if (isDownloaded) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.7)),
                        const SizedBox(width: 2),
                        Text("已下载", style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor.withOpacity(0.7))),
                      ],
                    ],
                  ),
                  if (!node.isFolder && node.size != null)
                    Text(OtherUtil.formatBytes(node.size ?? 0), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  if (node.isFolder)
                    Text('${node.children?.length ?? 0} 项', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (node.isFolder) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class FileTreeStickyHeader extends ConsumerWidget {
  final List<FileNode> roots;
  final Work? work;

  const FileTreeStickyHeader({super.key, required this.roots, this.work});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 假设你有一个管理路径的 Provider
    // 如果还没写，可以用 ref.watch(fileNavigationProvider)
    final breadcrumbs = ref.watch(breadcrumbProvider(BreadCrumbBarType.player));
    final breadcrumbNotifier = ref.read(
      breadcrumbProvider(BreadCrumbBarType.player).notifier,
    );

    // 获取当前层级的节点（计算逻辑移入 Header）
    final currentNodes = breadcrumbs.isEmpty
        ? roots
        : (breadcrumbs.last.children ?? []);

    final selectionNotifier = ref.read(fileSelectionProvider.notifier);
    ref.watch(fileSelectionProvider); // 监听选中变化

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 全选与操作栏
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 12, 12),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: selectionNotifier.getRootState(currentNodes),
                  onChanged: (_) =>
                      selectionNotifier.toggleSelectAll(currentNodes),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _buildSelectionInfo(theme, selectionNotifier),
                const Spacer(),
                _buildQueueButton(ref, selectionNotifier),
              ],
            ),
          ),

          // 2. 面包屑导航栏 (直接在内部调用 notifier)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: BreadcrumbBar(
              paths: breadcrumbs.map((node) => node.title).toList(),
              onHomeTap: () => breadcrumbNotifier.jumpTo(-1),
              onPathTap: (index) => breadcrumbNotifier.jumpTo(index),
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  // 内部辅助组件保持逻辑整洁
  Widget _buildSelectionInfo(ThemeData theme, FileSelectionNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '全选(当前层)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (notifier.count > 0)
          Text(
            '已选: ${notifier.totalSizeStr}',
            style: TextStyle(fontSize: 12, color: theme.primaryColor),
          ),
      ],
    );
  }
  Widget _buildQueueButton(WidgetRef ref, FileSelectionNotifier notifier) {
    return TextButton.icon(
      onPressed: notifier.musicCount == 0
          ? null
          : () {
        // 指定了类型后，这里的推断就会完全正确
        final audioFiles = notifier.selectedList
            .where((f) => f.isAudio)
            .toList();

        ref
            .read(playerControllerProvider.notifier)
            .addMultiInQueue(audioFiles, work!);
        Navigator.of(ref.context).pop();
      },
      icon: const Icon(Icons.queue_music, size: 20),
      label: const Text('加入队列'),
    );
  }
}
