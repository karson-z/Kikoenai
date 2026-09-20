import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/history/provider/history_controller_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

/// 播放历史：以"会话"为单位的单一时间线。
///
/// 每条记录是当时完整的播放队列快照，点击恢复整个会话；
/// 作品维度的断点续播由 WorkProgressPoint 索引独立承担。
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyControllerProvider);

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
          : _SessionTimeline(entries: historyList),
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '清空历史记录',
      content: '确定要清空所有播放会话与断点进度吗？此操作无法撤销。',
    );

    if (!confirmed) return;
    await ref.read(historyControllerProvider.notifier).clear();
  }
}

/// 时间线列表：按 今天 / 昨天 / 本周 / 更早 分段的会话卡片流。
class _SessionTimeline extends ConsumerWidget {
  const _SessionTimeline({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <({String? header, HistoryEntry? entry})>[];
    String? lastHeader;
    for (final entry in entries) {
      final header = _groupLabel(entry.lastPlayTime);
      if (header != lastHeader) {
        rows.add((header: header, entry: null));
        lastHeader = header;
      }
      rows.add((header: null, entry: entry));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.entry == null) {
          return _GroupHeader(label: row.header!);
        }
        return _SessionCard(entry: row.entry!);
      },
    );
  }

  String _groupLabel(int millis) {
    final now = DateTime.now();
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final dayDiff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (dayDiff == 0) return '今天';
    if (dayDiff == 1) return '昨天';
    if (dayDiff < 7) return '本周';
    return '更早';
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 单个会话卡片：封面（多作品叠层）+ 标题 + 当前曲目 + 来源/位置/时间 + 进度条。
class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = _SessionDisplay.of(entry);
    final theme = Theme.of(context);
    final controller = ref.read(historyControllerProvider.notifier);

    return Dismissible(
      key: ValueKey('history_session_${entry.session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      // 用 confirmDismiss 完成删除并返回 false，条目由 box.watch 触发的
      // 重建移除，避免 Dismissible 动画结束后仍留在树中的断言。
      confirmDismiss: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await controller.delete(entry.session.id);
        _showUndoSnackBar(messenger, ref);
        return false;
      },
      child: InkWell(
        onTap: () {
          ref.read(playerControllerProvider.notifier).restoreHistory(entry);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SessionCover(covers: display.covers),
              const SizedBox(width: 12),
              Expanded(
                child: _SessionInfo(entry: entry, display: display),
              ),
              _PlayButton(entry: entry),
              _MoreMenu(entry: entry, workId: display.firstWorkId),
            ],
          ),
        ),
      ),
    );
  }

  void _showUndoSnackBar(ScaffoldMessengerState messenger, WidgetRef ref) {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已删除该会话'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            ref.read(historyControllerProvider.notifier).upsert(entry);
          },
        ),
      ),
    );
  }
}

/// 会话展示信息：标题聚合、封面取值、多作品判定。
class _SessionDisplay {
  const _SessionDisplay({
    required this.title,
    required this.covers,
    required this.isMultiWork,
    required this.firstWorkId,
  });

  final String title;
  final List<String> covers;
  final bool isMultiWork;
  final int? firstWorkId;

  static _SessionDisplay of(HistoryEntry entry) {
    final scopeTitles = <String, String>{};
    final scopeCovers = <String, String>{};
    int? firstWorkId;
    for (final item in entry.session.queue) {
      scopeTitles.putIfAbsent(
        item.scopeKey,
        () => item.albumTitle ?? item.title,
      );
      final cover = item.coverUrl ?? item.smallCoverUrl ?? '';
      scopeCovers.putIfAbsent(item.scopeKey, () => cover);
      firstWorkId ??= item.workId;
    }

    final fallback = ScraperStorage().getWork(
      int.tryParse(entry.workId ?? '') ?? -1,
    );
    final primaryCover =
        entry.coverUrl ?? fallback?.mainCoverUrl ?? fallback?.samCoverUrl ?? '';

    var title = entry.title ?? entry.currentTrackTitle;
    if (scopeTitles.length > 1) {
      title = '${scopeTitles.values.first} 等 ${scopeTitles.length} 部';
    }

    // 多作品时最多叠 3 张封面，取最后播放位置附近的作用域更有代表性。
    var covers = scopeCovers.values
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (covers.isEmpty) covers = [primaryCover];
    if (scopeTitles.length > 1 && covers.length > 3) {
      covers = covers.sublist(0, 3);
    }
    if (scopeTitles.length <= 1) covers = [primaryCover];

    return _SessionDisplay(
      title: title,
      covers: covers,
      isMultiWork: scopeTitles.length > 1,
      firstWorkId: firstWorkId,
    );
  }
}

class _SessionCover extends StatelessWidget {
  const _SessionCover({required this.covers});

  final List<String> covers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = 56.0 + (covers.length - 1) * 12.0;
    return SizedBox(
      width: covers.length > 1 ? width : 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = covers.length - 1; i >= 0; i--)
            Positioned(
              left: i * 12.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SimpleExtendedImage(
                    covers[i],
                    width: 56,
                    height: 56,
                    loadingPlaceholder: Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.entry, required this.display});

  final HistoryEntry entry;
  final _SessionDisplay display;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = entry.session.queue;
    final index = queue.indexWhere((item) => item.id == entry.lastItemId);
    final safeIndex = index >= 0
        ? index
        : (entry.session.currentIndex >= 0 ? entry.session.currentIndex : 0);
    final position = safeIndex + 1;
    final trackTitle = entry.currentTrackTitle;
    final duration = entry.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trackTitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '正在听：$trackTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            _SourceBadge(source: entry.source),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '第 $position 首 / 共 ${queue.length} 首 · ${_relativeTime(entry.lastPlayTime)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (duration != null && duration > Duration.zero) ...[
          const SizedBox(height: 6),
          _TrackProgressBar(entry: entry, duration: duration),
        ],
      ],
    );
  }

  String _relativeTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.year == DateTime.now().year ? '' : '${dt.year}/'}${dt.month}/${dt.day}';
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final NodeSource? source;

  String get _label {
    return switch (source) {
      NodeSource.asmrServer || NodeSource.asmrGay => '在线',
      NodeSource.localWork => '本地',
      NodeSource.localSingle => '单曲',
      NodeSource.cloudDrive => '云盘',
      null => '未知',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TrackProgressBar extends StatelessWidget {
  const _TrackProgressBar({required this.entry, required this.duration});

  final HistoryEntry entry;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final progress = Duration(milliseconds: entry.lastProgressMs ?? 0);
    final fraction = (progress.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 3,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
      ),
    );
  }
}

class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: '恢复该会话',
      onPressed: () {
        ref.read(playerControllerProvider.notifier).restoreHistory(entry);
      },
      icon: Icon(
        Icons.play_circle_fill_rounded,
        size: 34,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// 更多操作：查看作品详情（可解析时）/ 删除该会话。
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.entry, required this.workId});

  final HistoryEntry entry;
  final int? workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = workId == null ? null : ScraperStorage().getWork(workId!);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      itemBuilder: (context) => [
        if (work != null)
          const PopupMenuItem(value: 'detail', child: Text('查看作品详情')),
        const PopupMenuItem(value: 'delete', child: Text('删除该会话')),
      ],
      onSelected: (value) {
        switch (value) {
          case 'detail':
            context.push(AppRoutes.detail, extra: {'work': work});
          case 'delete':
            ref
                .read(historyControllerProvider.notifier)
                .delete(entry.session.id);
        }
      },
    );
  }
}
