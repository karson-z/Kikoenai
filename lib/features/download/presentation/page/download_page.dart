import 'dart:convert';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _isTabClicking = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _isTabClicking = true;
        _scrollToSection(_tabController.index);
      }
    });
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_isTabClicking) return;

    final downloadingList = ref.read(downloadingTasksProvider);

    final int completedHeaderIndex =
        1 + (downloadingList.isEmpty ? 1 : downloadingList.length);

    final positions = _itemPositionsListener.itemPositions.value;

    if (positions.isEmpty) return;

    final minIndex = positions
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((ItemPosition min, ItemPosition position) =>
            position.itemLeadingEdge < min.itemLeadingEdge ? position : min)
        .index;

    if (minIndex >= completedHeaderIndex) {
      if (_tabController.index != 1) _tabController.animateTo(1);
    } else {
      if (_tabController.index != 0) _tabController.animateTo(0);
    }
  }

  void _scrollToSection(int tabIndex) {
    // 重新计算跳转位置
    int targetIndex = 0;
    if (tabIndex == 1) {
      final downloadingList = ref.read(downloadingTasksProvider);
      final Set<String> groups =
          downloadingList.map((e) => e.task.group).toSet();
      final int downloadingGroupCount = groups.isEmpty ? 1 : groups.length;
      targetIndex = 1 + downloadingGroupCount;
    }

    _itemScrollController
        .scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    )
        .then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _isTabClicking = false);
      });
    });
  }

  // --- 辅助方法：通用分组逻辑 ---
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

    // --- 1. 数据分组 ---
    final groupedDownloading = _groupTasks(downloadingList);
    final List<String> downloadingGroupKeys = groupedDownloading.keys.toList();

    final groupedCompleted = _groupTasks(completedList);
    final List<String> completedGroupKeys = groupedCompleted.keys.toList();

    // --- 2. 计算数量 ---
    // 如果为空，显示空状态占位符，占 1 个位置
    final int downloadingCount =
        downloadingGroupKeys.isEmpty ? 1 : downloadingGroupKeys.length;
    final int completedCount =
        completedGroupKeys.isEmpty ? 1 : completedGroupKeys.length;

    // 总数 = 标题1 + 下载组 + 标题2 + 完成组 + 底部垫高
    final int totalCount = 1 + downloadingCount + 1 + completedCount + 1;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 200,
            height: 40,
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ],
              ),
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              onTap: (index) {},
              tabs: const [Tab(text: '进行中'), Tab(text: '已完成')],
            ),
          ),
        ),
        actions: [
          AppActionButton(
              icon: Icons.play_arrow_rounded,
              tooltip: "全部开始",
              color: const Color(0xFF2563EB),
              onTap: () {}),
          const SizedBox(width: 8),
          AppActionButton(
              icon: Icons.pause_rounded,
              tooltip: "全部暂停",
              color: const Color(0xFF64748B),
              onTap: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: ScrollablePositionedList.builder(
        itemCount: totalCount,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemBuilder: (context, index) {
          // Index 0: 标题
          if (index == 0) return _buildSectionHeader("进行中");

          // Index 1 ~ N: 下载组
          if (index <= downloadingCount) {
            if (downloadingList.isEmpty) return _buildEmptyState(true);

            final groupIndex = index - 1;
            final groupName = downloadingGroupKeys[groupIndex];
            final tasks = groupedDownloading[groupName]!;

            return _buildDownloadingGroupCard(
                groupName, tasks);
          }
          final int completedHeaderIndex = 1 + downloadingCount;

          // Index N+1: 标题
          if (index == completedHeaderIndex) return _buildSectionHeader("已完成");

          final int groupStartIndex = completedHeaderIndex + 1;
          final int groupEndIndex = groupStartIndex + completedCount;

          // Index N+2 ~ M: 完成组
          if (index < groupEndIndex) {
            if (completedList.isEmpty) return _buildEmptyState(false);

            final groupIndex = index - groupStartIndex;
            final groupName = completedGroupKeys[groupIndex];
            final tasks = groupedCompleted[groupName]!;

            return _buildCompletedGroupCard(groupName, tasks);
          }
          // 底部
          return const SizedBox(height: 80);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B))),
    );
  }

  Widget _buildEmptyState(bool isDownloading) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isDownloading
                    ? Icons.cloud_download_outlined
                    : Icons.check_circle_outline,
                size: 28,
                color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 4),
            Text(isDownloading ? "暂无下载任务" : "暂无历史记录",
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingGroupCard(
      String groupName, List<TaskRecord> tasks) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(2),
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 必须与 Container 的圆角一致
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF1F5F9),
                child: coverUrl.isNotEmpty
                    ? Image.network(coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.downloading,
                        color: Colors.blueAccent))
                    : const Icon(Icons.downloading, color: Colors.blueAccent),
              ),
            ),
            title: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "正在处理 ${tasks.length} 个文件",
                style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
              ),
            ),
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 20, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155)),
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
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF64748B),
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
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: isPaused
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF3B82F6),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B)),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade600),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(2),
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: coverUrl.isNotEmpty
                  ? Image.network(coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.album, color: Colors.grey))
                  : const Icon(Icons.folder, color: Colors.blueGrey),
            ),
          ),
          // --- 标题 ---
          title: Text(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B)),
          ),
          // --- 副标题 ---
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.file_copy_outlined,
                    size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text("包含 ${tasks.length} 个文件",
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          // --- 【新增】右侧删除操作区 ---
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // 关键：防止 Row 撑满
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFF94A3B8), size: 20),
                tooltip: "删除整组",
                onPressed: () {
                  // 调用基于 KikoenaiDialog 的弹窗
                  _showDeleteGroupDialog(context, groupName, tasks);
                },
              ),
              // 手动把 ExpansionTile 默认被覆盖的箭头加回来
              const Icon(Icons.expand_more, color: Color(0xFFCBD5E1)),
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
    );
  }
  void _showDeleteGroupDialog(
      BuildContext context, String groupName, List<TaskRecord> tasks) {

    KikoenaiDialog.show(
      context: context,
      clickMaskDismiss: true, // 允许点击背景关闭
      builder: (context) {
        return AlertDialog(
          title: const Text("确认删除"),
          content: Text(
            "确定要删除 “$groupName” 中的所有 ${tasks.length} 个文件吗？\n此操作不可恢复。",
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            // 取消按钮
            TextButton(
              onPressed: () {
                // 使用封装的 dismiss 关闭弹窗
                KikoenaiDialog.dismiss();
              },
              child: const Text("取消", style: TextStyle(color: Colors.grey)),
            ),
            // 确认删除按钮
            TextButton(
              onPressed: () {
                // 1. 关闭弹窗
                KikoenaiDialog.dismiss();
                ref.read(allTasksProvider.notifier).deleteGroup(groupName);
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
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
      onTap: () => context.push(AppRoutes.detail,extra: {'work':jsonDecode(record.task.metaData)}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_getFileIcon(fileType),
                size: 24, color: const Color(0xFF94A3B8)),
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
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(fileType,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8))),
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
              onTap: () async{
                await ref.read(allTasksProvider.notifier).deleteTask(record.task);
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFCBD5E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    if (['MP3', 'WAV', 'FLAC', 'M4A'].contains(ext)) return Icons.audiotrack;
    if (['JPG', 'PNG', 'GIF'].contains(ext)) return Icons.image;
    if (['TXT', 'LRC'].contains(ext)) return Icons.description;
    return Icons.insert_drive_file;
  }
}
