import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../data/model/file_scanner_state.dart';
import '../provider/file_scanner_notifier.dart';

class PathManagerSheet extends ConsumerWidget {
  // 由于 KikoenaiDialog 内部管理了弹窗上下文，这里不再需要外部传入 ScrollController
  // 我们会在 ListView 内部创建 controller
  const PathManagerSheet({super.key});

  /// 对外暴露的静态调用方法，替代原来的 show 方法
  static Future<void> show(BuildContext context) {
    return KikoenaiDialog.showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 支持全屏或自定义高度
      useSafeArea: true,
      builder: (context) => const PathManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileScannerProvider);
    final notifier = ref.read(fileScannerProvider.notifier);

    final paths = state.savedPaths;
    final currentPath = state.currentPath;
    final currentMode = state.scanMode;

    // 计算初始 Tab 索引
    final initialIndex = switch (currentMode) {
      ScanMode.audio => 0,
      ScanMode.video => 1,
      ScanMode.subtitles => 2,
    };

    return Container(
      // 模拟原来 DraggableScrollableSheet 的视觉效果，设定固定高度或自适应
      // 这里建议使用约束或固定高度，配合 isScrollControlled: true
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        key: ValueKey(currentMode),
        length: 3,
        initialIndex: initialIndex,
        child: Column(
          mainAxisSize: MainAxisSize.min, // 重要：Column 高度随内容自适应
          children: [
            // 1. 顶部把手
            _buildDragHandle(context),

            // 2. 标题栏
            _buildHeader(context, notifier, paths),

            // 3. 药丸型 TabBar
            _buildPillTabBar(context, notifier),

            const SizedBox(height: 8),

            // 4. 列表区域 (使用 Expanded 撑满剩余空间)
            // 如果不想要固定高度，可以用 Flexible
            Expanded(
              child: paths.isEmpty
                  ? _buildEmptyManager(context)
                  : _buildPathList(context, ref, notifier, state, paths, currentPath),
            ),

            // 5. 底部按钮
            _buildBottomButton(notifier),
          ],
        ),
      ),
    );
  }

  // --- UI 组件拆分 ---

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FileScannerNotifier notifier, List<String> paths) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("扫描路径管理", style: Theme.of(context).textTheme.titleMedium),
              Text(
                "点击列表切换路径",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: paths.isEmpty ? null : () => _showClearConfirmation(context, notifier),
            child: Text(
              "清空",
              style: TextStyle(
                color: paths.isEmpty
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPillTabBar(BuildContext context, FileScannerNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            onTap: (index) {
              final targetMode = switch (index) {
                0 => ScanMode.audio,
                1 => ScanMode.video,
                2 => ScanMode.subtitles,
                _ => ScanMode.audio,
              };
              notifier.switchMode(targetMode);
            },
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.music_note, size: 16), SizedBox(width: 4), Text("音频")])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam, size: 16), SizedBox(width: 4), Text("视频")])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.subtitles, size: 16), SizedBox(width: 4), Text("字幕")])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathList(
      BuildContext context,
      WidgetRef ref,
      FileScannerNotifier notifier,
      FileScannerState state,
      List<String> paths,
      String? currentPath,
      ) {
    return ListView.separated(
      // 注意：这里移除了外部传入的 scrollController，由 ListView 自己管理
      // 如果需要拦截返回键，可以结合 ScrollController 做额外逻辑
      itemCount: paths.length,
      padding: const EdgeInsets.only(bottom: 80, top: 0),
      separatorBuilder: (c, i) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final path = paths[index];
        final folderName = path.split(Platform.pathSeparator).last;
        final parentPath = File(path).parent.path;
        final isSelected = path == currentPath;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          leading: CircleAvatar(
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondaryContainer,
            child: Icon(isSelected ? Icons.check : Icons.folder),
          ),
          title: Text(
            folderName.isEmpty ? path : folderName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(parentPath, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () async {
            await notifier.openPath(path);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Theme.of(context).colorScheme.error,
            tooltip: "移除此路径",
            onPressed: () async {
              await notifier.removeDirectory(path);
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(FileScannerNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: FilledButton.icon(
          onPressed: () => notifier.addDirectory(),
          icon: const Icon(Icons.add_rounded),
          label: const Text("添加新目录"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyManager(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "暂无扫描路径",
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  // --- 逻辑处理 ---

  void _showClearConfirmation(BuildContext context, FileScannerNotifier notifier) {
    // 这里也可以考虑使用 KikoenaiDialog.show 来统一风格
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("清空所有路径?"),
        content: const Text("这将移除当前模式下所有已添加的文件夹及缓存数据，此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              notifier.clearAllDirectories();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("确认清空"),
          ),
        ],
      ),
    );
  }
}
