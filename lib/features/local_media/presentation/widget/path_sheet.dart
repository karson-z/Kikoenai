import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';
import '../provider/file_scanner_notifier.dart';

class PathManagerSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const PathManagerSheet({super.key, required this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.55,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return PathManagerSheet(scrollController: scrollController);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileScannerProvider);
    final notifier = ref.read(fileScannerProvider.notifier);

    final paths = state.savedPaths;
    final currentPath = state.currentPath;
    final currentMode = state.scanMode;
    final isScanning = state.status == WorkerState.scanning;

    // 根据当前的枚举值，计算出应该激活哪个 Tab 索引
    int initialIndex = 0;
    switch (currentMode) {
      case ScanMode.audio:
        initialIndex = 0;
        break;
      case ScanMode.video:
        initialIndex = 1;
        break;
      case ScanMode.subtitles:
        initialIndex = 2;
        break;
    }

    // 整个 Sheet 用 DefaultTabController 包裹，接管状态
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Column(
        children: [
          // 1. 把手条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "扫描路径管理",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "点击列表切换路径",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: paths.isEmpty
                      ? null
                      : () => _showClearConfirmation(context, notifier),
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
          ),

          // 3. 自定义样式的药丸型 TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 40, // 控制整体高度
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15), // 整个区域的灰色背景
                borderRadius: BorderRadius.circular(20), // 外层大圆角
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0), // 留出一点内边距给白色滑块
                child: TabBar(
                  dividerColor: Colors.transparent, // 隐藏默认底线
                  indicatorSize: TabBarIndicatorSize.tab, // 指示器撑满单个 tab
                  labelColor: Colors.black87, // 选中文字颜色
                  unselectedLabelColor: Colors.grey.shade600, // 未选中文字颜色
                  // 核心：自定义指示器，也就是那个白色的高亮块
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
                  // 点击 Tab 时的联动事件
                  onTap: (index) {
                    if (isScanning) return; // 扫描中禁止切换

                    ScanMode targetMode;
                    switch (index) {
                      case 0:
                        targetMode = ScanMode.audio;
                        break;
                      case 1:
                        targetMode = ScanMode.video;
                        break;
                      case 2:
                        targetMode = ScanMode.subtitles;
                        break;
                      default:
                        targetMode = ScanMode.audio;
                    }
                    notifier.switchMode(targetMode);
                  },
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, size: 16),
                          SizedBox(width: 4),
                          Text("音频"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam, size: 16),
                          SizedBox(width: 4),
                          Text("视频"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.subtitles, size: 16),
                          SizedBox(width: 4),
                          Text("字幕"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 4. 列表区域
          Expanded(
            child: paths.isEmpty
                ? _buildEmptyManager(context)
                : ListView.separated(
              controller: scrollController,
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
                  selectedTileColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.1),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    child: Icon(
                      isSelected ? Icons.check : Icons.folder,
                    ),
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
                  subtitle: Text(
                    parentPath,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    notifier.startScan(path);
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: "移除此路径",
                    onPressed: () async {
                      notifier.removeDirectory(path);
                      await FileScannerStorage().clearByRootPath(path);
                    },
                  ),
                );
              },
            ),
          ),

          // 5. 底部固定按钮
          Container(
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
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, FileScannerNotifier notifier) {
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
}