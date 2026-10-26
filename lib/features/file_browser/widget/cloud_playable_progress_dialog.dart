import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';

/// 网盘递归收集媒体时的进度弹窗。
class CloudPlayableProgressDialog extends StatefulWidget {
  const CloudPlayableProgressDialog({
    super.key,
    required this.progress,
    this.onCancel,
  });

  final ValueNotifier<CloudPlayableProgress> progress;
  final VoidCallback? onCancel;

  static Future<void> show(
    BuildContext context,
    ValueNotifier<CloudPlayableProgress> progress, {
    VoidCallback? onCancel,
  }) {
    return KikoenaiDialog.show<void>(
      context: context,
      clickMaskDismiss: false,
      builder: (_) => PopScope(
        canPop: onCancel == null,
        child: CloudPlayableProgressDialog(
          progress: progress,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  State<CloudPlayableProgressDialog> createState() =>
      _CloudPlayableProgressDialogState();
}

class _CloudPlayableProgressDialogState
    extends State<CloudPlayableProgressDialog> {
  bool _cancelled = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.progress,
      builder: (context, value, _) {
        final color = Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : const Color(0xFF666666);
        return KikoenaiAlertDialog(
          titleText: '正在收集媒体',
          actions: widget.onCancel == null
              ? null
              : [
                  TextButton(
                    onPressed: _cancelled
                        ? null
                        : () {
                            setState(() => _cancelled = true);
                            widget.onCancel!();
                          },
                    child: Text(_cancelled ? '正在取消…' : '取消收集'),
                  ),
                ],
          content: DefaultTextStyle(
            style: TextStyle(color: color, fontSize: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text('已读取 ${value.completedDirectories} 个文件夹'),
                const SizedBox(height: 6),
                Text('待读取 ${value.pendingDirectories} 个文件夹'),
                const SizedBox(height: 6),
                Text('已找到 ${value.collectedFiles} 个可播放文件'),
                if (value.failedDirectories > 0) ...[
                  const SizedBox(height: 6),
                  Text('${value.failedDirectories} 个文件夹读取失败，将跳过'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
