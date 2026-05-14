import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/card/work_gallery_card.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/history/data/model/history_entry.dart';
import 'package:kikoenai/features/history/presentation/provider/history_controller_provider.dart';
import 'package:kikoenai/features/history/presentation/widget/history_horizontal_section.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  void _showAllEntries(
    BuildContext context,
    String title,
    List<HistoryEntry> entries,
  ) {
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
    BuildContext context,
    String title,
    List<HistoryEntry> previewItems,
    List<HistoryEntry> fullItems,
  ) {
    if (fullItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: HistoryHorizontalSection(
        title: title,
        items: previewItems,
        onMoreTap: fullItems.length > 20
            ? () => _showAllEntries(context, title, fullItems)
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
      width: 175,
      child: WorkGalleryCard(
        borderRadius: 12,
        aspectRatio: 4/3,
        imageUrl: cover,
        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
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
    await ref.read(historyControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyControllerProvider);
    final workEntries = ref.watch(historyByTypeProvider(HistoryEntryType.work));
    final localWorkEntries =
        ref.watch(historyByTypeProvider(HistoryEntryType.localWork));
    final singleWorkEntries =
        ref.watch(historyByTypeProvider(HistoryEntryType.singleWork));
    final workPreview =
        ref.watch(historyPreviewByTypeProvider(HistoryEntryType.work));
    final localWorkPreview =
        ref.watch(historyPreviewByTypeProvider(HistoryEntryType.localWork));
    final singleWorkPreview =
        ref.watch(historyPreviewByTypeProvider(HistoryEntryType.singleWork));

    return Scaffold(
      floatingActionButton: historyList.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'clear_history',
              onPressed: () => _clearHistory(context, ref),
              tooltip: '清空历史记录',
              child: const Icon(Icons.delete_forever),
            )
          : null,
      body: historyList.isEmpty
          ? const Center(child: Text('暂无历史记录'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSection(context, '作品历史', workPreview, workEntries),
                _buildSection(
                    context, '本地作品历史', localWorkPreview, localWorkEntries),
                _buildSection(
                    context, '单曲历史', singleWorkPreview, singleWorkEntries),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
