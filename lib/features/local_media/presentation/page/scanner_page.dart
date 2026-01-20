import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 确保导入了 ScanMode 枚举定义的文件
import '../../../../core/service/file/file_scanner_service.dart';
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
                const Flexible(
                  child: Text(
                    '媒体库',
                    style: TextStyle(fontSize: 18),
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
              // 这里显示当前模式更友好
              state.isScanning
                  ? state.statusMsg
                  : '共 ${state.totalCount} 个文件',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          // 修改点：调整容器宽度以适应 3 个按钮，或者让它自适应
          Container(
            height: 32,
            margin: const EdgeInsets.only(right: 8), // 稍微留点右边距
            // [修改 1] 泛型改为 ScanMode
            child: SegmentedButton<ScanMode>(
              style: ButtonStyle(
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                padding: WidgetStateProperty.all(
                  // 3个按钮空间较挤，进一步减小横向 Padding
                  const EdgeInsets.symmetric(horizontal: 4),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              showSelectedIcon: false,
              // [修改 2] 增加字幕 Segment
              segments: const [
                ButtonSegment<ScanMode>(
                  value: ScanMode.audio,
                  icon: Icon(Icons.music_note, size: 14), // 稍微调小图标以防溢出
                  label: Text("音频", style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment<ScanMode>(
                  value: ScanMode.video,
                  icon: Icon(Icons.videocam, size: 14),
                  label: Text("视频", style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment<ScanMode>(
                  value: ScanMode.subtitles,
                  icon: Icon(Icons.subtitles, size: 14),
                  label: Text("字幕", style: TextStyle(fontSize: 11)),
                ),
              ],
              // [修改 3] 绑定新的 state.scanMode
              selected: {state.scanMode},
              // [修改 4] 调用 switchMode
              onSelectionChanged: state.isScanning
                  ? null
                  : (Set<ScanMode> newSelection) {
                notifier.switchMode(newSelection.first);
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