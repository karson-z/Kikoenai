import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_worker.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../provider/file_scanner_notifier.dart';
import '../widget/file_scanner_panel.dart';
import '../widget/path_sheet.dart';
import '../widget/use_guide_dialog.dart';

class ScannerTestPage extends ConsumerWidget {
  const ScannerTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(fileScannerProvider);
    final scannerNotifier = ref.read(fileScannerProvider.notifier);
    final isScanning = scannerState.status == WorkerState.scanning;
    final currentMode = scannerState.scanMode;
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
              _getStatusText(scannerState.status, scannerState.scannedCount),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isScanning
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            child: SegmentedButton<ScanMode>(
              style: ButtonStyle(
                visualDensity:
                const VisualDensity(horizontal: -2, vertical: -2),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 4)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ScanMode.audio,
                  icon: Icon(Icons.music_note, size: 14),
                  label: Text("音频", style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: ScanMode.video,
                  icon: Icon(Icons.videocam, size: 14),
                  label: Text("视频", style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: ScanMode.subtitles,
                  icon: Icon(Icons.subtitles, size: 14),
                  label: Text("字幕", style: TextStyle(fontSize: 11)),
                ),
              ],
              selected: {currentMode},
              // 2. 切换模式时调用 Notifier 的 switchMode
              onSelectionChanged: (Set<ScanMode> newSelection) {
                if (!isScanning) {
                  scannerNotifier.switchMode(newSelection.first);
                }
              },
            ),
          ),
          Tooltip(
            message: isScanning ? "停止扫描" : "刷新",
            child: IconButton(
              icon: isScanning
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              onPressed: () {
                if (isScanning) {
                  scannerNotifier.stopScan();
                } else {
                  if (scannerState.savedPaths.isNotEmpty) {
                    scannerNotifier.startScan(scannerState.savedPaths.first);
                  } else {
                    PathManagerSheet.show(context);
                  }
                }
              },
            ),
          ),
        ],
      ),
      // 3. 根据内容构建页面
      body: scannerState.roots.isEmpty
          ? _buildEmptyStateView(context)
          : FileBrowserPanel(
        rootNodes: scannerState.roots,
        scanMode: currentMode,
      ),
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
}