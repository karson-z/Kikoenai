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
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final Set<String> _selectedIds = {};
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final historyList = ref.watch(historyControllerProvider);
    final visibleIds = historyList.map((entry) => entry.session.id).toSet();
    _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    if (historyList.isEmpty && _editing) {
      _editing = false;
    }

    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_editing) return;
        _exitEditing();
      },
      child: Scaffold(
        body: Stack(
          children: [
            historyList.isEmpty
                ? const Center(child: Text('暂无历史记录'))
                : _SessionTimeline(
                    entries: historyList,
                    editing: _editing,
                    selectedIds: _selectedIds,
                    onOpen: _restore,
                    onLongPress: _beginEditing,
                    onToggle: _toggle,
                    onDelete: _deleteOne,
                  ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _editing
                    ? _SelectionBar(
                        key: const ValueKey('history-selection-bar'),
                        selectedCount: _selectedIds.length,
                        allSelected:
                            historyList.isNotEmpty &&
                            _selectedIds.length == historyList.length,
                        onToggleAll: () => _toggleAll(historyList),
                        onDelete: _selectedIds.isEmpty
                            ? null
                            : () => _deleteSelected(historyList.length),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restore(HistoryEntry entry) {
    ref.read(playerControllerProvider.notifier).restoreHistory(entry);
  }

  void _beginEditing(HistoryEntry entry) {
    setState(() {
      _editing = true;
      _selectedIds
        ..clear()
        ..add(entry.session.id);
    });
  }

  void _toggle(HistoryEntry entry) {
    setState(() {
      final id = entry.session.id;
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  void _toggleAll(List<HistoryEntry> entries) {
    setState(() {
      if (_selectedIds.length == entries.length) {
        _selectedIds.clear();
        return;
      }
      _selectedIds
        ..clear()
        ..addAll(entries.map((entry) => entry.session.id));
    });
  }

  void _exitEditing() {
    setState(() {
      _editing = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteOne(HistoryEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(historyControllerProvider.notifier)
        .delete(entry.session.id);
    if (!mounted) return;
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

  Future<void> _deleteSelected(int totalCount) async {
    final count = _selectedIds.length;
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '删除播放记录',
      content: '删除这 $count 条播放记录？此操作无法撤销。',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;

    final deletingAll = count == totalCount;
    final ids = _selectedIds.toList();
    final controller = ref.read(historyControllerProvider.notifier);
    if (deletingAll) {
      await controller.clear();
    } else {
      await controller.deleteAll(ids);
    }
    if (!mounted) return;
    _exitEditing();
  }
}

/// 时间线列表：按 今天 / 昨天 / 本周 / 更早 分段的会话卡片流。
class _SessionTimeline extends ConsumerWidget {
  const _SessionTimeline({
    required this.entries,
    required this.editing,
    required this.selectedIds,
    required this.onOpen,
    required this.onLongPress,
    required this.onToggle,
    required this.onDelete,
  });

  final List<HistoryEntry> entries;
  final bool editing;
  final Set<String> selectedIds;
  final ValueChanged<HistoryEntry> onOpen;
  final ValueChanged<HistoryEntry> onLongPress;
  final ValueChanged<HistoryEntry> onToggle;
  final ValueChanged<HistoryEntry> onDelete;

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
      padding: EdgeInsets.only(bottom: editing ? 88 : 16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.entry == null) {
          return _GroupHeader(label: row.header!);
        }
        final entry = row.entry!;
        return _SessionCard(
          entry: entry,
          editing: editing,
          selected: selectedIds.contains(entry.session.id),
          onOpen: () => onOpen(entry),
          onLongPress: () => onLongPress(entry),
          onToggle: () => onToggle(entry),
          onDelete: () => onDelete(entry),
        );
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

/// 单个会话卡片：上次听到的作品封面在最上层，标题用该作品专辑名。
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.entry,
    required this.editing,
    required this.selected,
    required this.onOpen,
    required this.onLongPress,
    required this.onToggle,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final bool editing;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = _SessionDisplay.of(entry);
    final theme = Theme.of(context);

    final row = Material(
      color: selected
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: editing ? onToggle : onOpen,
        onLongPress: editing ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (editing) ...[
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
              ],
              _SessionCover(covers: display.covers),
              const SizedBox(width: 12),
              Expanded(
                child: _SessionInfo(entry: entry, display: display),
              ),
              if (!editing)
                _MoreMenu(
                  entry: entry,
                  workId: display.workId,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ),
    );

    if (editing) return row;
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
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: row,
    );
  }
}

/// 会话展示信息：标题和封面都以上次听到的曲目为准。
class _SessionDisplay {
  const _SessionDisplay({
    required this.title,
    required this.covers,
    required this.workId,
  });

  final String title;
  final List<String> covers;
  final int? workId;

  static _SessionDisplay of(HistoryEntry entry) {
    final current = entry.lastItem;
    final scopes = <String, PlaybackItem>{};
    if (current != null) scopes[current.scopeKey] = current;
    for (final item in entry.session.queue) {
      scopes.putIfAbsent(item.scopeKey, () => item);
    }

    final fallback = ScraperStorage().getWork(current?.workId ?? -1);
    final currentCover =
        current?.displayCoverUrl ??
        entry.coverUrl ??
        fallback?.mainCoverUrl ??
        fallback?.samCoverUrl ??
        '';
    final covers = <String>[
      if (currentCover.isNotEmpty) currentCover,
      for (final item in scopes.values)
        if (current == null || item.scopeKey != current.scopeKey)
          if ((item.displayCoverUrl ?? '').isNotEmpty) item.displayCoverUrl!,
    ];

    return _SessionDisplay(
      title: current?.albumTitle ?? current?.title ?? entry.title ?? '',
      covers: scopes.length > 1 ? covers.take(3).toList() : covers.take(1).toList(),
      workId: current?.workId,
    );
  }
}

class _SessionCover extends StatelessWidget {
  const _SessionCover({required this.covers});

  final List<String> covers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = covers.isEmpty ? const [''] : covers;
    final width = 56.0 + (visible.length - 1) * 12.0;
    return SizedBox(
      width: visible.length > 1 ? width : 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
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
                    visible[i],
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
            '上次听到：$trackTitle',
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
    final now = DateTime.now();
    final dayDiff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (dayDiff >= 7) {
      final year = dt.year == now.year ? '' : '${dt.year}/';
      return '$year${dt.month}/${dt.day}';
    }
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
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

/// 更多操作：查看作品详情（可解析时）/ 删除该会话。
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({
    required this.entry,
    required this.workId,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final int? workId;
  final VoidCallback onDelete;

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
            onDelete();
        }
      },
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
    required this.onDelete,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE6E6E6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              KikoenaiAlertDialog.textAction(
                context,
                label: allSelected ? '取消全选' : '全选',
                isConfirm: true,
                onPressed: onToggleAll,
              ),
              const Spacer(),
              KikoenaiAlertDialog.textAction(
                context,
                label: '删除（$selectedCount）',
                isDestructive: true,
                enabled: onDelete != null,
                onPressed: onDelete ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
