import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/file_scanner_provider.dart';
import '../widget/file_scanner_panel.dart';
import '../widget/path_sheet.dart';
import '../widget/use_guide_dialog.dart';

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileScannerProvider);
    final notifier = ref.read(fileScannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    '媒体库',
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const UsageGuideDialog(),
                    );
                  },
                ),
              ],
            ),
            Text(
              state.isScanning ? state.statusMsg : '共 ${state.totalCount} 个文件',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            height: 32,
            child: SegmentedButton<bool>(
              // 1. 【核心修复】添加样式配置
              style: ButtonStyle(
                // 压缩视觉密度，减少默认的垂直间距（非常重要）
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                // 移除或减小内部的 Padding，确保内容能居中
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
                // 确保点击区域和布局对齐
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),

              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  // 建议：在该高度下，Icon 和 Text 可能有些拥挤，可以微调 Icon 大小
                  icon: Icon(Icons.music_note, size: 16),
                  label: Text("音频", style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.videocam, size: 16),
                  label: Text("视频", style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {state.isAudioMode},
              onSelectionChanged: state.isScanning
                  ? null
                  : (Set<bool> newSelection) {
                notifier.toggleMode(newSelection.first);
              },
            ),
          ),
          Tooltip(
            message: "重新扫描所有",
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: state.isScanning
                  ? null
                  : () => notifier.refreshAll(),
            ),
          ),
        ],
      ),

      body: state.rootPaths.isEmpty
          ? _buildEmptyStateView(context, notifier)
          : const FileBrowserPanel(),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.folder_copy_outlined),
        label: const Text("管理路径"),
        onPressed: () {
          // --- 调用新封装的组件 ---
          PathManagerSheet.show(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyStateView(BuildContext context, FileScannerNotifier notifier) {
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
            "添加本地文件夹开始扫描媒体文件",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => notifier.addDirectory(),
            icon: const Icon(Icons.add),
            label: const Text("添加文件夹"),
          ),
        ],
      ),
    );
  }
}