import 'package:flutter/material.dart';

class DlLibraryHeader extends StatelessWidget {
  const DlLibraryHeader({
    super.key,
    required this.queueCount,
    required this.onOpenQueue,
  });

  final int queueCount;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          const Icon(Icons.library_music_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DL库',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox.square(
            dimension: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: '解析队列',
              onPressed: onOpenQueue,
              icon: Badge(
                isLabelVisible: queueCount > 0,
                label: Text(queueCount > 99 ? '99+' : '$queueCount'),
                child: const Icon(Icons.swap_vert_circle_outlined, size: 21),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
