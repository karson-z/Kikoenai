import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/local_media/provider/local_media_exclusion_provider.dart';

/// 当前扫描根目录的已排除文件和文件夹。
class ExcludedMediaSheet extends ConsumerWidget {
  const ExcludedMediaSheet({super.key, required this.rootPath});

  final String rootPath;

  static Future<void> show(BuildContext context, String rootPath) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ExcludedMediaSheet(rootPath: rootPath),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(localMediaExclusionsProvider(rootPath));
    return SafeArea(
      child: entries.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(child: Text('没有已排除的文件或文件夹')),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: Icon(
                    entry.isFolder ? Icons.folder_off_outlined : Icons.hide_source,
                  ),
                  title: Text(entry.relativePath),
                  trailing: TextButton(
                    onPressed: () => restoreLocalMediaExclusion(ref, entry),
                    child: const Text('恢复'),
                  ),
                );
              },
            ),
    );
  }
}
