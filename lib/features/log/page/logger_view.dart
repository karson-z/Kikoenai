import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart' show Level;
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key, this.logStore = const KikoenaiLogStore()});

  final KikoenaiLogStore logStore;

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  KikoenaiLogSnapshot _snapshot = const KikoenaiLogSnapshot([], 0, false);
  Timer? _timer;
  bool _isLoading = true;
  bool _reading = false;
  bool _live = true;
  bool _follow = true;
  bool _copying = false;
  String? _error;
  String _query = '';
  Level? _level;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_live) _loadLogs(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<KikoenaiLogRecord> get _visibleRecords => _snapshot.records
      .where((entry) {
        final levelMatches = _level == null || entry.level == _level;
        return levelMatches &&
            (_query.isEmpty || entry.text.toLowerCase().contains(_query));
      })
      .toList(growable: false);

  Future<void> _loadLogs({bool silent = false}) async {
    if (_reading) return;
    _reading = true;
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final snapshot = await widget.logStore.readSnapshot();
      if (!mounted) return;
      final changed =
          snapshot.fileBytes != _snapshot.fileBytes || _error != null;
      setState(() {
        _snapshot = snapshot;
        _error = null;
      });
      if (_follow && (changed || !silent)) _scrollToBottom();
    } catch (error) {
      if (mounted) setState(() => _error = '读取日志失败：$error');
    } finally {
      _reading = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空系统日志？'),
        content: const Text('将删除所有已保存的日志，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空日志'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await widget.logStore.clear();
    if (!mounted) return;
    if (success) await _loadLogs();
    _notify(success ? '日志已清空' : '清空日志失败');
  }

  void _notify(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copy({bool all = false, String? text}) async {
    if (_copying) return;
    setState(() => _copying = true);
    try {
      final content =
          text ??
          (all
              ? await widget.logStore.readAll()
              : _visibleRecords.map((record) => record.text).join('\n\n'));
      if (content.isEmpty) {
        _notify('暂无可复制的日志');
        return;
      }
      await Clipboard.setData(ClipboardData(text: content));
      _notify(all ? '全部日志已复制' : '日志已复制到剪贴板');
    } catch (error) {
      _notify('复制失败：$error');
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // Lazy lists can refine their extent after laying out the target items.
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _showDetail(KikoenaiLogRecord entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '日志详情',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '复制此条日志',
                    onPressed: () => _copy(text: entry.text),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    tooltip: '关闭详情',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    entry.text,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final compact =
        MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom <
        580;
    final visible = _visibleRecords;
    final warnings = _snapshot.records
        .where((r) => r.level == Level.warning)
        .length;
    final errors = _snapshot.records
        .where((r) => r.level == Level.error || r.level == Level.fatal)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统日志'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reading ? null : () => _loadLogs(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: '日志操作',
            onSelected: (action) {
              switch (action) {
                case 'copy':
                  _copy(all: true);
                case 'filtered':
                  _copy();
                case 'clear':
                  _clearLogs();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'copy',
                enabled: !_copying,
                child: const Text('全部复制'),
              ),
              PopupMenuItem(
                value: 'filtered',
                enabled: visible.isNotEmpty && !_copying,
                child: const Text('复制筛选结果'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: Text('清空日志')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.terminal_rounded,
                                    color: colors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      '运行记录',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _live ? '实时更新' : '已暂停',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: _live
                                              ? colors.primary
                                              : colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  Text('${_snapshot.records.length} 条记录'),
                                  Text(
                                    '$warnings 条警告',
                                    style: TextStyle(
                                      color: _levelColor(Level.warning, colors),
                                    ),
                                  ),
                                  Text(
                                    '$errors 条错误',
                                    style: TextStyle(color: colors.error),
                                  ),
                                  Text(
                                    _formatBytes(_snapshot.fileBytes),
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (!compact) const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: '搜索内容、来源或异常',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清除搜索',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          filled: true,
                          fillColor: colors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final level in <Level?>[
                              null,
                              Level.error,
                              Level.warning,
                              Level.info,
                              Level.debug,
                              Level.fatal,
                              Level.trace,
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(_levelLabel(level)),
                                  selected: _level == level,
                                  onSelected: (_) =>
                                      setState(() => _level = level),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              showCheckmark: false,
                              avatar: Icon(
                                _live
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text('实时更新'),
                              selected: _live,
                              onSelected: (value) {
                                setState(() => _live = value);
                                if (value) _loadLogs(silent: true);
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('跟随最新'),
                              selected: _follow,
                              onSelected: (value) {
                                setState(() => _follow = value);
                                if (value) _scrollToBottom();
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '显示 ${visible.length} 条',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (_snapshot.truncated)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '仅展示最近 2000 条 / 2 MB，全部复制可获取完整日志。',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const Divider(height: 1),
                if (_error != null)
                  Material(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: colors.onErrorContainer),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _loadLogs(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _query.isNotEmpty || _level != null
                                      ? Icons.search_off_rounded
                                      : Icons.receipt_long_outlined,
                                  size: 48,
                                  color: colors.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isLoading
                                      ? '正在读取日志…'
                                      : _snapshot.records.isEmpty
                                      ? '暂无日志记录'
                                      : '没有匹配的日志',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击记录查看完整内容与堆栈',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                      : NotificationListener<UserScrollNotification>(
                          onNotification: (notification) {
                            if (_follow &&
                                _scrollController.hasClients &&
                                _scrollController.position.extentAfter > 48) {
                              setState(() => _follow = false);
                            }
                            return false;
                          },
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                88,
                              ),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) => _LogTile(
                                entry: visible[index],
                                onTap: () => _showDetail(visible[index]),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: '滚动到底部',
        onPressed: () {
          setState(() => _follow = true);
          _scrollToBottom();
        },
        child: const Icon(Icons.vertical_align_bottom_rounded),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.onTap});
  final KikoenaiLogRecord entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = _levelColor(entry.level, colors);
    final time = entry.time?.toLocal().toIso8601String();
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.level?.name.toUpperCase() ?? 'LEGACY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    time == null
                        ? '未知时间'
                        : time.replaceFirst('T', ' ').substring(0, 23),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    entry.tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) => bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

String _levelLabel(Level? level) => switch (level) {
  null => '全部',
  Level.trace => '追踪',
  Level.debug => '调试',
  Level.info => '信息',
  Level.warning => '警告',
  Level.error => '错误',
  Level.fatal => '致命',
  _ => level.name,
};

Color _levelColor(Level? level, ColorScheme colors) => switch (level) {
  Level.warning =>
    colors.brightness == Brightness.dark
        ? const Color(0xFFFFCA80)
        : const Color(0xFF966000),
  Level.error || Level.fatal => colors.error,
  Level.debug => colors.primary,
  Level.info => colors.tertiary,
  _ => colors.onSurfaceVariant,
};
