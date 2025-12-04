import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../../../../core/utils/data/other.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';
import '../../data/model/file_node.dart';

class FileNodeBrowser extends ConsumerStatefulWidget {
  final Work work;
  final List<FileNode> rootNodes;

  const FileNodeBrowser({
    super.key,
    required this.work,
    required this.rootNodes,
  });

  @override
  ConsumerState<FileNodeBrowser> createState() => _FileNodeBrowserState();
}

class _FileNodeBrowserState extends ConsumerState<FileNodeBrowser> {
  final List<FileNode> _breadcrumb = [];
  bool _historyChecked = false; // ✅ 标记是否已经检查过历史
  @override
  void initState() {
    super.initState();
    _checkHistoryOnce();
  }
  Future<void> _checkHistoryOnce() async {
    final playerController = ref.read(playerControllerProvider.notifier);
    final history = await playerController.checkHistoryForWork(widget.work);

    if (!_historyChecked && mounted && history != null) {
      _historyChecked = true; // ✅ 只执行一次
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检测到上次播放: ${history.currentTrackTitle}'),
          action: SnackBarAction(
            label: '恢复',
            onPressed: () {
              playerController.restoreHistory(widget.rootNodes, widget.work, history);
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  List<FileNode> get _currentNodes =>
      _breadcrumb.isEmpty ? widget.rootNodes : _breadcrumb.last.children ?? [];

  void _enterFolder(FileNode folder) {
    setState(() => _breadcrumb.add(folder));
  }
  void _goToBreadcrumbIndex(int index) {
    setState(() {
      if (index == -1) {
        _breadcrumb.clear();
      } else {
        _breadcrumb.removeRange(index + 1, _breadcrumb.length);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: BreadcrumbHeaderDelegate(
              breadcrumb: _breadcrumb,
              onRootTap: () => _goToBreadcrumbIndex(-1),
              onCrumbTap: _goToBreadcrumbIndex,
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          if (_currentNodes.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text("该目录为空")),
            )
          else
            SliverList.builder(
              itemCount: _currentNodes.length,
              itemBuilder: (_, index) {
                final node = _currentNodes[index];
                return ListTile(
                  leading: Icon(_iconByType(node)),
                  title: Text(node.title),
                  subtitle: Text(
                    "${node.isAudio ? "时长:" : "类型："}"
                        "${node.isAudio ? TimeFormatter.formatSeconds(node.duration?.toInt() ?? 0) : node.type.name}",
                  ),
                  onTap: node.isFolder
                      ? () => _enterFolder(node)
                      : () => ref
                      .read(playerControllerProvider.notifier)
                      .handleFileTap(node, widget.work, _currentNodes),
                );
              },
            ),
        ],
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
class _BreadcrumbHeader extends StatelessWidget {
  final List<FileNode> breadcrumb;
  final VoidCallback onRootTap;
  final void Function(int index) onCrumbTap;

  const _BreadcrumbHeader({
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: onRootTap,
              child: const Text(
                '根目录',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (int i = 0; i < breadcrumb.length; i++) ...[
              const Icon(Icons.chevron_right, size: 20),
              GestureDetector(
                onTap: () => onCrumbTap(i),
                child: Text(
                  breadcrumb[i].title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
/// pinned header delegate
class BreadcrumbHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<FileNode> breadcrumb;
  final VoidCallback onRootTap;
  final void Function(int index) onCrumbTap;

  BreadcrumbHeaderDelegate({
    required this.breadcrumb,
    required this.onRootTap,
    required this.onCrumbTap,
  });


  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _BreadcrumbHeader(
      breadcrumb: breadcrumb,
      onRootTap: onRootTap,
      onCrumbTap: onCrumbTap,
    );
  }

  @override
  bool shouldRebuild(covariant BreadcrumbHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  double get maxExtent => 68;

  @override
  double get minExtent => 68;
}
