import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/player/data/model/playback_session.dart';
import '../../../../../core/service/audio/audio_extension.dart';
import '../../../../../core/service/lyrics/match_lyrics_service.dart';
import '../../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../provider/player_controller_provider.dart';
import '../../provider/player_lyrics_match_provider.dart';

class LyricsMappingSheet extends ConsumerStatefulWidget {
  const LyricsMappingSheet({Key? key}) : super(key: key);

  static Future<void> show({
    BuildContext? context,
  }) {
    return KikoenaiDialog.showBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context != null ? Theme.of(context).scaffoldBackgroundColor : null,
      builder: (context) => const LyricsMappingSheet(),
    );
  }

  @override
  ConsumerState<LyricsMappingSheet> createState() => _LyricsMappingSheetState();
}

class _LyricsMappingSheetState extends ConsumerState<LyricsMappingSheet> {
  late Map<String, FileNode?> _draftMapping;
  late List<MediaItem> _currentWorkPlaylist;

  @override
  void initState() {
    super.initState(); 
    _initData();
  }

  void _initData() {
    final matchState = ref.read(lyricsMatchControllerProvider);
    final playerState = ref.read(playerControllerProvider);

    _draftMapping = Map.of(matchState.subtitleMapping);

    final currentWorkId = matchState.currentWorkId;
    _currentWorkPlaylist = playerState.playbackQueue
        .where((item) => item.workId == currentWorkId)
        .toList().toMediaItems();
  }

  void _clearMapping(String trackId) {
    setState(() {
      _draftMapping[trackId] = null;
    });
  }

  void _resetAll() {
    setState(() {
      _draftMapping.clear();
    });
  }

  Future<void> _handleSelectSubtitle(String trackId, List<FileNode> availableSubtitles) async {
    final selectedNode = await KikoenaiDialog.show<FileNode>(
      context: context,
      builder: (context) => _SubtitlePickerDialog(
        availableSubtitles: availableSubtitles,
      ),
    );

    if (selectedNode != null) {
      setState(() {
        _draftMapping[trackId] = selectedNode;
      });
    }
  }

  void _saveMapping() {
    ref.read(lyricsMatchControllerProvider.notifier).updateMapping(_draftMapping);
    KikoenaiDialog.dismiss();
  }

  /// 处理单策略一键匹配
  void _handleSingleStrategyMatch(MatchLyrics strategy) {
    // 1. 过滤出还未匹配的音频
    final unmatchedPlayList = _currentWorkPlaylist
        .where((track) => _draftMapping[track.id] == null)
        .toList();

    // 2. 过滤出尚未被占用的可用字幕
    final usedSubtitles = _draftMapping.values.whereType<FileNode>().toSet();
    final matchState = ref.read(lyricsMatchControllerProvider);
    final availableSubtitles = matchState.lyricsList
        .where((node) => !usedSubtitles.contains(node))
        .toList();

    if (unmatchedPlayList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有音轨均已匹配')),
      );
      return;
    }

    if (availableSubtitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的剩余字幕文件')),
      );
      return;
    }

    // 3. 执行核心策略
    final newMatches = MatchLyrics.matchBySingleStrategy(
      playList: unmatchedPlayList,
      lyricList: availableSubtitles,
      strategy: strategy,
    );

    if (newMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未能根据该规则匹配到任何结果')),
      );
      return;
    }

    // 4. 更新 UI
    setState(() {
      _draftMapping.addAll(newMatches);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功匹配 ${newMatches.length} 项')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSubtitles = ref.watch(
        lyricsMatchControllerProvider.select((state) => state.lyricsList)
    );
    final theme = Theme.of(context);

    // 计算统计数据
    final matchedCount = _currentWorkPlaylist.where((t) => _draftMapping[t.id] != null).length;
    final totalCount = _currentWorkPlaylist.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('字幕匹配', style: TextStyle(fontSize: 18)),
            Text(
              '已匹配 $matchedCount / $totalCount',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => KikoenaiDialog.dismiss(),
        ),
        actions: [
          PopupMenuButton<MatchLyrics>(
            tooltip: '一键匹配',
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.auto_awesome),
            onSelected: _handleSingleStrategyMatch,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AccurateMatch(),
                child: const Row(
                  children: [
                    Icon(Icons.title, size: 18),
                    SizedBox(width: 12),
                    Text('精确匹配 (完全同名)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FuzzyMatch(),
                child: const Row(
                  children: [
                    Icon(Icons.blur_on, size: 18),
                    SizedBox(width: 12),
                    Text('模糊匹配 (相似度)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SequenceMatch(),
                child: const Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 18),
                    SizedBox(width: 12),
                    Text('序号匹配 (提取数字)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _currentWorkPlaylist.length,
              itemBuilder: (context, index) {
                final track = _currentWorkPlaylist[index];
                final mappedNode = _draftMapping[track.id];
                return _buildTrackCard(track, mappedNode, index + 1, availableSubtitles);
              },
            ),
          ),
          // --- 底部悬浮操作栏 ---
          _buildBottomActionBar(theme),
        ],
      ),
    );
  }

  /// 构建底部固定操作栏
  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetAll,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('全部重置'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _saveMapping,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('保存更改'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个音轨的卡片视图
  Widget _buildTrackCard(MediaItem track, FileNode? node, int index, List<FileNode> availableSubtitles) {
    final hasNode = node != null;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasNode
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.error.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部分：音轨标题
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    track.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _handleSelectSubtitle(track.id, availableSubtitles),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: hasNode
                            ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                            : theme.colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasNode ? Icons.subtitles : Icons.warning_amber_rounded,
                            size: 18,
                            color: hasNode ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasNode ? node.title : '未关联字幕，点击选择',
                              style: TextStyle(
                                color: hasNode ? theme.colorScheme.onSurface : theme.colorScheme.error,
                                fontSize: 13,
                                fontWeight: hasNode ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 操作按钮
                if (hasNode) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
                    tooltip: '取消关联',
                    onPressed: () => _clearMapping(track.id),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 字幕选择弹窗组件 (稍作美化)
// ==========================================
class _SubtitlePickerDialog extends StatelessWidget {
  final List<FileNode> availableSubtitles;

  const _SubtitlePickerDialog({
    Key? key,
    required this.availableSubtitles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择字幕文件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: availableSubtitles.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 48, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              const Text('没有可用的字幕文件'),
            ],
          ),
        )
            : ListView.separated(
          itemCount: availableSubtitles.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final node = availableSubtitles[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text(node.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                KikoenaiDialog.dismiss(popWith: node);
              },
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => KikoenaiDialog.dismiss(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}