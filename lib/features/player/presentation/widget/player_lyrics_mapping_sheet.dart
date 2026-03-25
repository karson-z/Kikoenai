import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/file_node.dart';

import '../../../../core/widgets/common/kikoenai_dialog.dart';

class LyricsMappingSheet extends StatefulWidget {
  final List<MediaItem> playlist;
  final Map<String, FileNode?> initialMapping;
  final List<FileNode?> availableSubtitles;

  const LyricsMappingSheet({
    Key? key,
    required this.playlist,
    required this.initialMapping,
    required this.availableSubtitles,
  }) : super(key: key);

  static Future<Map<String, FileNode?>?> show({
    BuildContext? context,
    required List<MediaItem> playlist,
    required Map<String, FileNode?> initialMapping,
    required List<FileNode?> availableSubtitles,
  }) {
    return KikoenaiDialog.showBottomSheet<Map<String, FileNode?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context != null ? Theme.of(context).scaffoldBackgroundColor : null, // 若为空交由内部处理主题色
      builder: (context) => LyricsMappingSheet(
        playlist: playlist,
        initialMapping: initialMapping,
        availableSubtitles: availableSubtitles,
      ),
    );
  }

  @override
  State<LyricsMappingSheet> createState() => _LyricsMappingSheetState();
}

class _LyricsMappingSheetState extends State<LyricsMappingSheet> {
  late Map<String, FileNode?> _currentMapping;

  @override
  void initState() {
    super.initState();
    _currentMapping = Map.of(widget.initialMapping);
  }

  void _clearMapping(String trackId) {
    setState(() {
      _currentMapping[trackId] = null;
    });
  }

  void _resetAll() {
    setState(() {
      _currentMapping.clear();
    });
  }

  Future<void> _handleSelectSubtitle(String trackId) async {
    final nonNullSubtitles = widget.availableSubtitles.whereType<FileNode>().toList();

    final selectedNode = await KikoenaiDialog.show<FileNode>(
      context: context,
      builder: (context) => _SubtitlePickerDialog(
        availableSubtitles: nonNullSubtitles,
      ),
    );

    if (selectedNode != null) {
      setState(() {
        _currentMapping[trackId] = selectedNode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动匹配字幕'),
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
            onPressed: () {
              KikoenaiDialog.dismiss(popWith: _currentMapping);
            },
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
              itemCount: widget.playlist.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = widget.playlist[index];
                final mappedNode = _currentMapping[track.id];
                return _buildMappingRow(track, mappedNode, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(MediaItem track, FileNode? node, int index) {
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: hasNode ? null : () => _handleSelectSubtitle(track.id),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: hasNode
                  ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '更换字幕',
                  onPressed: () => _handleSelectSubtitle(track.id),
                ),
                IconButton(
                  icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
                  tooltip: '取消关联',
                  onPressed: () => _clearMapping(track.id),
                ),
              ]
                  : [
                TextButton(
                  onPressed: () => _handleSelectSubtitle(track.id),
                  child: const Text('选择'),
                ),
              ],
            ),
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