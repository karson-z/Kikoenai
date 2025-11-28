import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../data/model/file_node.dart';

class FileNodeBrowser extends ConsumerStatefulWidget {
  final Work work;
  final List<FileNode> rootNodes;
  final void Function(FileNode node)? onFileTap;
  final double height; // 卡片高度

  const FileNodeBrowser({
    super.key,
    required this.work,
    required this.rootNodes,
    this.onFileTap,
    required this.height,
  });

  @override
  ConsumerState<FileNodeBrowser> createState() => _FileNodeBrowserState();
}

class _FileNodeBrowserState extends ConsumerState<FileNodeBrowser> {
  final List<FileNode> _breadcrumb = [];

  // 拿到当前层级的所有节点
  List<FileNode> get _currentNodes =>
      _breadcrumb.isEmpty ? widget.rootNodes : _breadcrumb.last.children ?? [];

  void _enterFolder(FileNode folder) {
    setState(() => _breadcrumb.add(folder));
  }

  void _goToBreadcrumbIndex(int index) {
    setState(() {
      _breadcrumb.removeRange(index + 1, _breadcrumb.length);
    });
  }

  void _handleFileTap(FileNode node) async {
    widget.onFileTap?.call(node);

    if (node.isAudio) {
      final audioFiles = _currentNodes.where((n) => n.isAudio).toList();
      final playerController = ref.read(playerControllerProvider.notifier);
      final mediaList = audioFiles.map((node) {
        return MediaItem(
          id: node.hash.toString(),
          album: node.workTitle,
          title: node.title,
          artist: OtherUtil.joinVAs(widget.work.vas),
          extras: {'url': node.mediaStreamUrl, 'mainCoverUrl': widget.work.mainCoverUrl,'samCorverUrl': widget.work.samCoverUrl},
        );
      }).toList();

      // 清空队列然后添加新列表
      await playerController.clear();
      await playerController.addAll(mediaList);

      // 因为 mediaList 只包含音频文件，所以要映射实际点击的音频下标
      final audioTapIndex = audioFiles.indexOf(node);
      await playerController.skipTo(audioTapIndex);
      await playerController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 面包屑
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _goToBreadcrumbIndex(-1),
                    child: const Text(
                      '根目录',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (int i = 0; i < _breadcrumb.length; i++) ...[
                    const Icon(Icons.chevron_right, size: 20),
                    GestureDetector(
                      onTap: () => _goToBreadcrumbIndex(i),
                      child: Text(
                        _breadcrumb[i].title,
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // 文件列表独立滚动
            Expanded(
              child: _currentNodes.isEmpty
                  ? const Center(child: Text("该目录为空"))
                  : ListView.builder(
                itemCount: _currentNodes.length,
                itemBuilder: (context, index) {
                  final node = _currentNodes[index];
                  return ListTile(
                    leading: Icon(_iconByType(node)),
                    title: Text(node.title),
                    subtitle: Text("type: ${node.type.name}"),
                    onTap: node.isFolder
                        ? () => _enterFolder(node)
                        : () => _handleFileTap(node),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconByType(FileNode node) {
    if (node.isAudio) return Icons.audiotrack;
    if (node.isImage) return Icons.image;
    if (node.isText) return Icons.text_snippet;
    return Icons.folder;
  }
}
