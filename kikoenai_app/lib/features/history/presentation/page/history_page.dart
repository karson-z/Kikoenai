import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/widgets/card/work_gallery_card.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/history/presentation/provider/history_controller_provider.dart';
import 'package:kikoenai/features/history/presentation/widget/history_horizontal_section.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Widget _buildSection(
    BuildContext context,
    String title,
    List<HistoryEntry> previewItems,
  ) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: HistoryHorizontalSection(
        title: title,
        items: previewItems,
        onMoreTap: previewItems.length > 20
            ? () {
          //TODO 跳转到显示全部历史记录的页面。
        }
            : null,
        itemBuilder: _buildHistoryCard,
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryEntry entry) {
    final workId = entry.lastItem?.workId;
    final work = workId == null ? null : ScraperStorage().getWork(workId);
    final cover =
        entry.coverUrl ??
        work?.mainCoverUrl ??
        work?.samCoverUrl ?? '';
    final title = entry.title ?? work?.title ?? entry.currentTrackTitle;
    final subtitle = entry.currentTrackTitle;
    final progressLabel = _buildProgressLabel(entry);

    return SizedBox(
      width: 175,
      child: Consumer(
        builder: (context, ref, _) {
          return WorkGalleryCard(
            borderRadius: 12,
            aspectRatio: 4 / 3,
            imageUrl: cover,
            padding: const EdgeInsets.symmetric(vertical: 12),
            title: title,
            subtitle: subtitle,
            progressLabel: progressLabel,
            onPlayTap: () {
              ref.read(playerControllerProvider.notifier).restoreHistory(entry);
            },
            onTap: work == null
                ? null
                : () {
                    context.push(
                      AppRoutes.detail,
                      extra: {'work': work, 'isLocal': entry.isLocalWork},
                    );
                  },
          );
        },
      ),
    );
  }

  String? _buildProgressLabel(HistoryEntry entry) {
    final duration = entry.duration;
    if (duration == null || duration <= Duration.zero) return null;

    final progress = Duration(milliseconds: entry.lastProgressMs ?? 0);
    final safeProgress = progress > duration ? duration : progress;
    return '${_formatDuration(safeProgress)} / ${_formatDuration(duration)}';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
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
    final workPreview = ref.watch(
      historyBySourceProvider(NodeSource.asmrServer),
    );
    final localWorkPreview = ref.watch(
      historyBySourceProvider(NodeSource.localWork),
    );
    final singleWorkPreview = ref.watch(
      historyBySourceProvider(NodeSource.localSingle),
    );

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
                _buildSection(context, '作品历史', workPreview),
                _buildSection(
                  context,
                  '本地作品历史',
                  localWorkPreview,
                ),
                _buildSection(
                  context,
                  '单曲历史',
                  singleWorkPreview,
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
