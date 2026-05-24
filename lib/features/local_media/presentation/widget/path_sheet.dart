import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/local_media/data/model/file_scanner_state.dart';
import '../../data/repository/scanner_path_repository.dart';
import '../provider/file_path_notifier.dart';
import '../provider/file_scanner_notifier.dart';

class PathManagerSheet extends ConsumerStatefulWidget {
  const PathManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return KikoenaiDialog.showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const PathManagerSheet(),
    );
  }

  @override
  ConsumerState<PathManagerSheet> createState() => _PathManagerSheetState();
}

class _PathManagerSheetState extends ConsumerState<PathManagerSheet> {
  late ScanMode _currentMode;

  @override
  void initState() {
    super.initState();
    final activeTarget = ref.read(scanTargetsProvider.notifier).getActiveTarget();
    _currentMode = activeTarget?.scanMode ?? ScanMode.audio;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(scanTargetsProvider);
    final notifier = ref.read(scanTargetsProvider.notifier);
    final currentTargets = notifier.getTargetsByMode(_currentMode);
    final ScanTarget? activeTarget = notifier.getActiveTarget();

    final initialIndex = switch (_currentMode) {
      ScanMode.audio => 0,
      ScanMode.video => 1,
      ScanMode.subtitles => 2,
    };

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 3,
        initialIndex: initialIndex,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(context),
            _buildHeader(context, notifier, currentTargets),
            _buildPillTabBar(context),
            const SizedBox(height: 8),
            Expanded(
              child: currentTargets.isEmpty
                  ? _buildEmptyManager(context)
                  : _buildPathList(context, ref, currentTargets, activeTarget),
            ),
            _buildBottomButton(ref),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHeader(BuildContext context, dynamic notifier, List<dynamic> currentTargets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("文件夹管理", style: Theme.of(context).textTheme.titleMedium),
          TextButton(
            onPressed: currentTargets.isEmpty
                ? null
                : () => _showClearConfirmation(context, ref),
            child: Text(
              "清空",
              style: TextStyle(
                color: currentTargets.isEmpty
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPillTabBar(BuildContext context) {
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
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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
              setState(() {
                _currentMode = switch (index) {
                  0 => ScanMode.audio,
                  1 => ScanMode.video,
                  2 => ScanMode.subtitles,
                  _ => ScanMode.audio,
                };
              });
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
      List<ScanTarget> targets,
      ScanTarget? scanTarget,
      ) {
    return ListView.separated(
      itemCount: targets.length,
      padding: const EdgeInsets.only(bottom: 80, top: 0),
      separatorBuilder: (c, i) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final target = targets[index];
        final path = target.path;
        final normalizedPath = path.replaceAll('\\', '/');
        final folderName = normalizedPath.split('/').last;

        final isSelected = scanTarget != null &&
            path == scanTarget.path &&
            target.scanMode == scanTarget.scanMode;

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
          subtitle: Text(
            _formatRelativeTime(target.lastScannedAt),
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          onTap: () async {
            await ref.read(scanTargetsProvider.notifier).selectTarget(path: path, mode: target.scanMode);
            ref.read(fileScannerProvider.notifier).changeActiveTarget(target);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Theme.of(context).colorScheme.error,
            tooltip: "移除此路径",
            onPressed: () async {
              await ref.read(scanTargetsProvider.notifier).removeTarget(path: path, mode: _currentMode);
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: FilledButton.icon(
          onPressed: () async {
            final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory == null) return;
            final scanTarget = await ref.read(scanTargetsProvider.notifier).addTarget(path: selectedDirectory, mode: _currentMode);
            if (scanTarget == null) return;
            await ref.read(scanTargetsProvider.notifier).selectTarget(path: scanTarget.path, mode: scanTarget.scanMode);
            if (!mounted) return;
            ref.read(fileScannerProvider.notifier).changeActiveTarget(scanTarget);
            Navigator.pop(context);
          },
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

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("清空当前模式路径?"),
        content: const Text("这将移除当前选定模式下所有已添加的文件夹及缓存数据，此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              final fileScannerNotifier = ref.read(fileScannerProvider.notifier);
              final activeState = ref.watch(fileScannerProvider);

              if (activeState.scanMode == _currentMode && activeState.rootPath.isNotEmpty) {
                fileScannerNotifier.handleCurrentPathRemoved();
              }

              final notifier = ref.read(scanTargetsProvider.notifier);
              final currentTargets = notifier.getTargetsByMode(_currentMode);

              for (final target in currentTargets) {
                await ScannerPathRepository.instance.deleteTarget(target.path, _currentMode);
              }

              await notifier.refreshTargets();

              if (!context.mounted) return;
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
  String _formatRelativeTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      return "状态：从未扫描";
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timestamp;

    if (difference < 0) return "状态：刚刚扫描";

    final seconds = difference ~/ 1000;
    if (seconds < 60) return "上次扫描：刚刚";

    final minutes = seconds ~/ 60;
    if (minutes < 60) return "上次扫描：$minutes 分钟前";

    final hours = minutes ~/ 60;
    if (hours < 24) return "上次扫描：$hours 小时前";

    final days = hours ~/ 24;
    if (days < 30) return "上次扫描：$days 天前";

    final months = days ~/ 30;
    return "上次扫描：$months 个月前";
  }
}