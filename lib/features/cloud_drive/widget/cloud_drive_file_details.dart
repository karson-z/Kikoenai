import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

Future<void> showCloudDriveFileDetails(
  BuildContext context,
  FileNode node,
  List<FileNode> siblings,
) async {
  final theme = Theme.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _DetailLine(icon: Icons.folder_outlined, text: node.path ?? '-'),
            const SizedBox(height: 10),
            _DetailLine(
              icon: Icons.data_usage,
              text: _formatFileSize(node.size ?? 0),
            ),
            const SizedBox(height: 10),
            _DetailLine(
              icon: Icons.schedule,
              text: node.lastModified == 0
                  ? '-'
                  : _formatDateTime(node.lastModified),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filledTonal(
                tooltip: '复制路径',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: node.path ?? ''));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已复制文件路径')));
                  }
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) return '-';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _formatDateTime(int milliseconds) {
  final value = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
