import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_breadcrumb_header.dart';
import 'package:kikoenai/core/widgets/common/back_button_interceptor.dart';
import 'package:kikoenai/core/widgets/common/custom_bottom_type.dart';
import 'package:kikoenai/core/widgets/common/custom_side_sheet_type.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_file_details.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// 所有文件来源共用页面尺寸和滚动布局，数据读取由各来源负责。
SliverWoltModalSheetPage buildFileManagementPage(Widget child) =>
    NonScrollingWoltModalSheetPage(
      navBarHeight: 0,
      hasTopBarLayer: false,
      child: child,
    );

WoltModalType fileManagementModalType(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 500
    ? const _FileManagementBottomType()
    : const CustomSideSheetType();

/// Wolt 0.11 的默认手柄会拦截顶部整行触摸。将触摸区限制在手柄周围，
/// 两侧按钮直接接收点击，拖拽仍交由 Wolt 外层手势处理。
class _FileManagementBottomType extends CustomBottomType {
  const _FileManagementBottomType() : super(showDragHandle: false);

  @override
  Widget decoratePageContent(
    BuildContext context,
    Widget child,
    bool useSafeArea,
  ) {
    final theme = Theme.of(context);
    final modalTheme = theme.extension<WoltModalSheetThemeData>();
    final size = modalTheme?.dragHandleSize ?? const Size(36, 4);
    final color =
        modalTheme?.dragHandleColor ??
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return super.decoratePageContent(
      context,
      Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: size.width < kMinInteractiveDimension
                    ? kMinInteractiveDimension
                    : size.width,
                height: kMinInteractiveDimension,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    label: MaterialLocalizations.of(
                      context,
                    ).modalBarrierDismissLabel,
                    container: true,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: size.width,
                        height: size.height,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(size.height / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      useSafeArea,
    );
  }
}

typedef FileManagementSortChoice = ({String id, String label});

/// 本地索引、作品文件树和网盘目录共用的文件管理界面。
///
/// 不直接访问索引、Provider 或网络；每个来源传入自己的快照和操作。
class FileManagementSheet extends StatelessWidget {
  const FileManagementSheet({
    super.key,
    required this.title,
    required this.onBack,
    required this.onClose,
    required this.segments,
    required this.onHome,
    required this.onSegment,
    required this.nodes,
    required this.selectedCount,
    required this.selectAllLabel,
    required this.selectionState,
    required this.onToggleAll,
    required this.nodeSelection,
    required this.onToggleNode,
    required this.onOpenFolder,
    required this.sortChoices,
    required this.selectedSort,
    required this.onSort,
    required this.onAddQueue,
    this.selectionSize,
    this.scrollController,
    this.currentFilePath,
    this.folderDescription,
    this.isDownloaded,
    this.showDownload = false,
    this.onDownload,
    this.isAtRoot = true,
    this.isLoading = false,
    this.showProgress = false,
    this.errorMessage,
    this.onRetry,
    this.onRefresh,
    this.onManageSource,
    this.onLocate,
    this.loadMoreLabel,
    this.onLoadMore,
    this.currentFileMissing = false,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final List<String> segments;
  final VoidCallback onHome;
  final ValueChanged<int> onSegment;
  final List<FileNode> nodes;
  final int selectedCount;
  final String selectAllLabel;
  final bool? selectionState;
  final VoidCallback? onToggleAll;
  final bool? Function(FileNode) nodeSelection;
  final ValueChanged<FileNode> onToggleNode;
  final ValueChanged<FileNode> onOpenFolder;
  final List<FileManagementSortChoice> sortChoices;
  final String selectedSort;
  final ValueChanged<String> onSort;
  final VoidCallback? onAddQueue;
  final String? selectionSize;
  final ScrollController? scrollController;
  final String? currentFilePath;
  final String Function(FileNode)? folderDescription;
  final bool Function(FileNode)? isDownloaded;
  final bool showDownload;
  final VoidCallback? onDownload;
  final bool isAtRoot;
  final bool isLoading;
  final bool showProgress;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final VoidCallback? onManageSource;
  final VoidCallback? onLocate;
  final String? loadMoreLabel;
  final VoidCallback? onLoadMore;
  final bool currentFileMissing;

  @override
  Widget build(BuildContext context) => BackButtonPriorityWrapper(
    zIndex: 110,
    onBack: () {
      onBack();
      return true;
    },
    child: Column(
      children: [
        FileManagementHeader(
          title: title,
          onBack: onBack,
          onRefresh: onRefresh,
          onManageSource: onManageSource,
        ),
        FileBreadcrumb(
          segments: segments,
          onHomeTap: onHome,
          onSegmentTap: onSegment,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Checkbox(
                tristate: true,
                value: selectionState,
                onChanged: onToggleAll == null ? null : (_) => onToggleAll!(),
              ),
              Expanded(
                child: Text(
                  selectAllLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (showDownload)
                IconButton(
                  tooltip: '下载',
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 20),
                ),
              if (currentFilePath != null)
                IconButton(
                  tooltip: '定位正在播放的文件',
                  onPressed: onLocate,
                  icon: const Icon(Icons.my_location, size: 20),
                ),
              PopupMenuButton<String>(
                tooltip: '排序',
                icon: const Icon(Icons.sort, size: 20),
                initialValue: selectedSort,
                onSelected: onSort,
                itemBuilder: (_) => sortChoices
                    .map(
                      (choice) => PopupMenuItem(
                        value: choice.id,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: choice.id == selectedSort
                                  ? const Icon(Icons.check, size: 18)
                                  : null,
                            ),
                            Expanded(child: Text(choice.label)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (showProgress) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent(context)),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '已选 $selectedCount 项',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (selectionSize != null)
                      Text(
                        selectionSize!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAddQueue,
                        icon: const Icon(Icons.queue_music, size: 20),
                        label: const Text('加入队列'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    // 错误提示和空目录同样参与滚动，短屏及大字体不会挤压列表产生溢出。
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(onPressed: onRetry, child: const Text('重试')),
                      if (!isAtRoot)
                        TextButton(
                          onPressed: onBack,
                          child: const Text('返回上级'),
                        ),
                      if (onManageSource != null)
                        TextButton(
                          onPressed: onManageSource,
                          child: const Text('来源设置'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (nodes.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(errorMessage == null ? '该目录为空' : '目录读取失败'),
              ),
            ),
          )
        else
          SliverFixedExtentList(
            itemExtent: 72,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNode(context, nodes[index]),
              childCount: nodes.length,
            ),
          ),
        if (loadMoreLabel != null)
          SliverToBoxAdapter(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(loadMoreLabel!),
            ),
          )
        else if (currentFileMissing && errorMessage == null)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('当前文件不在此目录，可能已移动或删除', textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _buildNode(BuildContext context, FileNode node) {
    final current = currentFilePath != null && node.path == currentFilePath;
    final downloaded = isDownloaded?.call(node) ?? false;
    final icon = node.isFolder
        ? Icons.folder
        : node.isVideo
        ? Icons.videocam
        : node.isAudio
        ? Icons.audiotrack
        : node.isImage
        ? Icons.image
        : node.isText
        ? Icons.description
        : Icons.insert_drive_file_outlined;
    final metadata = [
      if (current) '正在播放',
      if (downloaded) '已下载',
      if (node.isFolder)
        folderDescription?.call(node) ?? '文件夹'
      else if (node.size != null)
        OtherUtil.formatBytes(node.size!),
    ].join(' · ');
    return ListTile(
      key: ValueKey(node.path ?? node.keyId),
      contentPadding: const EdgeInsets.only(left: 4, right: 8),
      leading: Checkbox(
        tristate: true,
        value: nodeSelection(node),
        onChanged: (_) => onToggleNode(node),
      ),
      title: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: node.isFolder
                ? Colors.amber
                : current
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: downloaded ? TextStyle(color: Colors.grey.shade600) : null,
            ),
          ),
          if (downloaded) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      subtitle: metadata.isEmpty
          ? null
          : Text(metadata, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: current,
      trailing: node.isFolder ? const Icon(Icons.chevron_right) : null,
      onTap: () => node.isFolder ? onOpenFolder(node) : onToggleNode(node),
      onLongPress: () => showCloudDriveFileDetails(context, node, nodes),
    );
  }
}

class FileManagementHeader extends StatelessWidget {
  const FileManagementHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onRefresh,
    this.onManageSource,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onManageSource;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: '返回',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      if (onRefresh != null)
        IconButton(
          tooltip: '刷新目录',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      if (onManageSource != null)
        IconButton(
          tooltip: '来源设置',
          onPressed: onManageSource,
          icon: const Icon(Icons.settings_outlined),
        ),
    ],
  );
}
