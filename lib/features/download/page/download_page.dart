import 'dart:convert';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import '../../../../core/service/download/download_service.dart';
import '../../../../core/widgets/common/action_button.dart';
import '../provider/download_provider.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // 动态颜色定义 (Slate 风格)
  Color get _cSurface => isDark ? const Color(0xFF1E293B) : Colors.white; // 卡片背景
  Color get _cBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0); // 边框
  Color get _cTextMain => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B); // 主标题
  Color get _cTextSub => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // 副标题/图标
  Color get _cIconBg => isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9); // 图标底色

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedTabIndex == _tabController.index) return;
      setState(() => _selectedTabIndex = _tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(allTasksProvider.notifier).refreshTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<TaskRecord>> _groupTasks(List<TaskRecord> list) {
    final Map<String, List<TaskRecord>> grouped = {};
    for (var record in list) {
      final groupName = (record.task.group.isEmpty) ? "其他" : record.task.group;
      if (!grouped.containsKey(groupName)) {
        grouped[groupName] = [];
      }
      grouped[groupName]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final downloadingList = ref.watch(downloadingTasksProvider);
    final completedList = ref.watch(completedTasksProvider);
    final downloadService = ref.read(downloadServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final groupedDownloading = _groupTasks(downloadingList);
    final groupedCompleted = _groupTasks(completedList);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const ValueKey('download_tabs'),
            width: 180,
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              labelPadding: EdgeInsets.zero,
              labelColor: colorScheme.onSurface,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              tabs: const [Tab(text: '下载中'), Tab(text: '已完成')],
            ),
          ),
        ),
        actions: _selectedTabIndex == 0 ? [
          AppActionButton(
              icon: Icons.play_arrow_rounded,
              tooltip: "全部开始",
              color: const Color(0xFF2563EB),
              onTap: downloadingList.isEmpty
                  ? null
                  : () {
                      final tasks = downloadingList
                          .map((e) => e.task)
                          .whereType<DownloadTask>()
                          .toList();
                      downloadService.resumeAll(tasks);
                    }),
          const SizedBox(width: 8),
          AppActionButton(
              icon: Icons.pause_rounded,
              tooltip: "全部暂停",
              color: const Color(0xFF64748B),
              onTap: downloadingList.isEmpty
                  ? null
                  : () {
                      final tasks = downloadingList
                          .map((e) => e.task)
                          .whereType<DownloadTask>()
                          .toList();
                      downloadService.pauseAll(tasks);
                    }),
          const SizedBox(width: 16),
        ] : const [],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(groupedDownloading, isDownloading: true),
          _buildTaskList(groupedCompleted, isDownloading: false),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    Map<String, List<TaskRecord>> groupedTasks, {
    required bool isDownloading,
  }) {
    final groupNames = groupedTasks.keys.toList(growable: false);
    if (groupNames.isEmpty) {
      return Center(child: _buildEmptyState(isDownloading));
    }
    return ListView.builder(
      key: PageStorageKey<String>(
        isDownloading ? 'downloading_tasks' : 'completed_tasks',
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: groupNames.length,
      itemBuilder: (context, index) {
        final groupName = groupNames[index];
        final tasks = groupedTasks[groupName]!;
        return isDownloading
            ? _buildDownloadingGroupCard(groupName, tasks)
            : _buildCompletedGroupCard(groupName, tasks);
      },
    );
  }

  Widget _buildEmptyState(bool isDownloading) {
    return Column(
      key: ValueKey(
        isDownloading ? 'downloading_empty_state' : 'completed_empty_state',
      ),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
            isDownloading
                ? Icons.cloud_download_outlined
                : Icons.check_circle_outline,
            size: 28,
            // 空状态图标颜色
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        const SizedBox(height: 4),
        Text(isDownloading ? "暂无下载任务" : "暂无历史记录",
            style: TextStyle(
              // 空状态文字颜色
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 12)),
      ],
    );
  }

  // --- 下载中分组卡片 ---
  Widget _buildDownloadingGroupCard(String groupName, List<TaskRecord> tasks) {
    final DownloadService service = ref.read(downloadServiceProvider);
    String coverUrl = "";
    try {
      if (tasks.isNotEmpty && tasks.first.task.metaData.isNotEmpty) {
        final meta = jsonDecode(tasks.first.task.metaData);
        coverUrl = meta['thumbnailCoverUrl'] ?? meta['mainCoverUrl'] ?? "";
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cSurface, // [适配] 动态背景
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder), // [适配] 动态边框
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5), // 暗色模式去除阴影
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          // [样式] 去除分割线
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 48,
                height: 48,
                color: _cIconBg, // [适配] 图片底色
                child: coverUrl.isNotEmpty
                    ? Image.network(coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.downloading,
                        color: isDark ? Colors.blue[400] : Colors.blueAccent))
                    : Icon(Icons.downloading,
                    color: isDark ? Colors.blue[400] : Colors.blueAccent),
              ),
            ),
            title: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _cTextMain), // [适配] 标题颜色
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "正在处理 ${tasks.length} 个文件",
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)
                ),
              ),
            ),
            // [适配] 箭头颜色
            iconColor: _cTextSub,
            collapsedIconColor: _cTextSub,
            children: tasks.map((record) {
              return Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: _buildDownloadingSubItem(record, service),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadingSubItem(TaskRecord record, DownloadService service) {
    final isPaused = record.status == TaskStatus.paused;
    final progress = record.progress.clamp(0.0, 1.0);
    final filename = record.task.filename;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cBorder.withAlpha(isDark ? 50 : 255)), // [适配] 子项边框
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155)),
                ),
              ),
              // 暂停/继续
              InkWell(
                onTap: () => isPaused
                    ? service.resumeTask(record.task.taskId)
                    : service.pauseTask(record.task.taskId),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 20,
                    color: isPaused
                        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6))
                        : _cTextSub,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 取消
              InkWell(
                onTap: () => service.cancel(record.task.taskId),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    // [适配] 进度条背景
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    color: isPaused
                        ? _cTextSub
                        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _cTextSub),
              ),
            ],
          ),
          if (isPaused)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text("已暂停",
                  style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B))),
            ),
        ],
      ),
    );
  }

  // --- 已完成分组卡片 ---
  Widget _buildCompletedGroupCard(String groupName, List<TaskRecord> tasks) {
    String coverUrl = "";
    try {
      if (tasks.isNotEmpty && tasks.first.task.metaData.isNotEmpty) {
        final meta = jsonDecode(tasks.first.task.metaData);
        coverUrl = meta['thumbnailCoverUrl'] ?? meta['mainCoverUrl'] ?? "";
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cSurface, // [适配] 动态背景
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder), // [适配] 动态边框，与进行中一致
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5),
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          // [样式] 去除分割线
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Container(
                  color: _cIconBg, // [适配] 图片底色
                  child: coverUrl.isNotEmpty
                      ? Image.network(coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.album, color: Colors.grey))
                      : const Icon(Icons.folder, color: Colors.blueGrey),
                ),
              ),
            ),
            title: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _cTextMain), // [适配] 标题
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.file_copy_outlined,
                      size: 12, color: _cTextSub),
                  const SizedBox(width: 4),
                  Text("包含 ${tasks.length} 个文件",
                      style: TextStyle(
                          fontSize: 12, color: _cTextSub)),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: _cTextSub, size: 20),
                  tooltip: "删除整组",
                  onPressed: () {
                    _showDeleteGroupDialog(context, groupName, tasks);
                  },
                ),
                // [适配] 箭头颜色
                Icon(Icons.expand_more, color: _cTextSub),
              ],
            ),
            children: tasks.map((record) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: _buildCompletedSubItem(record),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showDeleteGroupDialog(
      BuildContext context, String groupName, List<TaskRecord> tasks) {
    KikoenaiDialog.show(
      context: context,
      clickMaskDismiss: true,
      builder: (context) {
        return KikoenaiAlertDialog(
          titleText: "确认删除",
          contentText:
              "确定要删除 “$groupName” 中的所有 ${tasks.length} 个文件吗？\n此操作不可恢复。",
          actions: [
            KikoenaiAlertDialog.textAction(
              context,
              label: "取消",
              onPressed: () => KikoenaiDialog.dismiss(),
            ),
            KikoenaiAlertDialog.textAction(
              context,
              label: "删除",
              isDestructive: true,
              onPressed: () {
                KikoenaiDialog.dismiss();
                ref.read(allTasksProvider.notifier).deleteGroup(groupName);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedSubItem(TaskRecord record) {
    final String filename = record.task.filename;
    final String fileType = filename.split('.').last.toUpperCase();
    return InkWell(
      onTap: () => context.push(AppRoutes.detail,
          extra: {'work': jsonDecode(record.task.metaData)}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(OtherUtil.getFileIcon(fileType),
                size: 24,
                // [适配] 图标颜色
                color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        // [适配] 文件名
                        color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(fileType,
                          style: TextStyle(
                              fontSize: 10, color: _cTextSub)),
                      const SizedBox(width: 8),
                      const Icon(Icons.check,
                          size: 10, color: Color(0xFF16A34A)),
                      const SizedBox(width: 2),
                      const Text("完成",
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF16A34A))),
                    ],
                  )
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                await ref
                    .read(allTasksProvider.notifier)
                    .deleteTask(record.task);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(Icons.delete_outline,
                    size: 18, color: isDark ? Colors.grey[600] : const Color(0xFFCBD5E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
