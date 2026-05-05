import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../../../../core/service/audio/audio_extension.dart';
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

    // 初始化草稿状态与当前作品的播放列表
    final matchState = ref.read(lyricsMatchControllerProvider);
    final playerState = ref.read(playerControllerProvider);

    _draftMapping = Map.of(matchState.subtitleMapping);

    // 过滤出仅属于当前作品的音轨
    final currentWorkId = matchState.currentWorkId;
    _currentWorkPlaylist = playerState.playlist
        .where((item) => item.workData?.id == currentWorkId)
        .toList();
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
    // 直接调用 Controller 提交变更
    ref.read(lyricsMatchControllerProvider.notifier).updateMapping(_draftMapping);
    KikoenaiDialog.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    // 监听可用的字幕列表
    final availableSubtitles = ref.watch(
        lyricsMatchControllerProvider.select((state) => state.lyricsList)
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('字幕匹配'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => KikoenaiDialog.dismiss(),
        ),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: const Text('全部重置'),
          ),
          TextButton(
            onPressed: _saveMapping,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('音频轨道', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('关联字幕文件', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _currentWorkPlaylist.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = _currentWorkPlaylist[index];
                final mappedNode = _draftMapping[track.id];
                return _buildMappingRow(track, mappedNode, index + 1, availableSubtitles);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(MediaItem track, FileNode? node, int index, List<FileNode> availableSubtitles) {
    final hasNode = node != null;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '$index. ${track.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: hasNode ? null : () => _handleSelectSubtitle(track.id, availableSubtitles),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: hasNode ? Colors.transparent : theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: hasNode ? null : Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasNode ? Icons.subtitles_outlined : Icons.warning_amber_rounded,
                      size: 18,
                      color: hasNode ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasNode ? (node.title) : '未关联 (点击选择)',
                        style: TextStyle(
                          color: hasNode ? theme.colorScheme.onSurface : theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: hasNode
                ? [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: '更换字幕',
                onPressed: () => _handleSelectSubtitle(track.id, availableSubtitles),
              ),
              IconButton(
                icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
                tooltip: '取消关联',
                onPressed: () => _clearMapping(track.id),
              ),
            ]
                : [
              TextButton(
                onPressed: () => _handleSelectSubtitle(track.id, availableSubtitles),
                child: const Text('选择'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubtitlePickerDialog extends StatelessWidget {
  final List<FileNode> availableSubtitles;

  const _SubtitlePickerDialog({
    Key? key,
    required this.availableSubtitles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择字幕文件', style: TextStyle(fontSize: 18)),
      contentPadding: const EdgeInsets.only(top: 16),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: availableSubtitles.isEmpty
            ? const Center(child: Text('没有可用的字幕文件'))
            : ListView.builder(
          itemCount: availableSubtitles.length,
          itemBuilder: (context, index) {
            final node = availableSubtitles[index];
            return ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                KikoenaiDialog.dismiss(popWith: node);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => KikoenaiDialog.dismiss(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}