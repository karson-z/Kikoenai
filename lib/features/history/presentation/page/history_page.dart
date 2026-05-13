import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/card/work_gallery_card.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/history/data/model/history_entry.dart';
import 'package:kikoenai/features/history/presentation/widget/history_horizontal_section.dart';

import '../../data/repository/history_respository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const int _previewLimit = 20;

  final HistoryRepository _historyRepository = HistoryRepository.instance;
  List<HistoryEntry> historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final list = _historyRepository.getAll();
    if (!mounted) return;
    setState(() {
      historyList = list;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有历史记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _historyRepository.clear();
    if (!mounted) return;
    setState(() {
      historyList.clear();
    });
  }

  List<HistoryEntry> _entriesOf(HistoryEntryType type) {
    return historyList.where((entry) => entry.historyType == type).toList();
  }

  void _showAllEntries(String title, List<HistoryEntry> entries) {
    KikoenaiDialog.showBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(context, entries[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<HistoryEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final previewItems = entries.take(_previewLimit).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: HistoryHorizontalSection(
        title: title,
        items: previewItems,
        onMoreTap: entries.length > _previewLimit
            ? () => _showAllEntries(title, entries)
            : null,
        itemBuilder: _buildHistoryCard,
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryEntry entry) {
    final work = entry.work;
    final cover = work?.mainCoverUrl ?? work?.samCoverUrl ?? placeholderImage;
    final title = work?.title ?? entry.lastPlayTrack.title;
    final subtitle = entry.currentTrackTitle;

    return SizedBox(
      width: 170,
      child: WorkGalleryCard(
        imageUrl: cover,
        title: title,
        subtitle: subtitle,
        onTap: work == null
            ? null
            : () {
                context.push(
                  AppRoutes.detail,
                  extra: {
                    'work': work,
                    'isLocal': entry.historyType == HistoryEntryType.localWork,
                  },
                );
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workEntries = _entriesOf(HistoryEntryType.work);
    final localWorkEntries = _entriesOf(HistoryEntryType.localWork);
    final singleWorkEntries = _entriesOf(HistoryEntryType.singleWork);

    return Scaffold(
      floatingActionButton: historyList.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'clear_history',
              onPressed: _clearHistory,
              tooltip: '清空历史记录',
              child: const Icon(Icons.delete_forever),
            )
          : null,
      body: historyList.isEmpty
          ? const Center(child: Text('暂无历史记录'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSection('作品历史', workEntries),
                _buildSection('本地作品历史', localWorkEntries),
                _buildSection('单曲历史', singleWorkEntries),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
