import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于剪贴板
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/user/presentation/view_models/provider/file_preview_provider.dart';

class TextPreviewPage extends ConsumerWidget {
  final String url;
  final String title;

  const TextPreviewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听文本内容 Provider
    final asyncContent = ref.watch(textContentProvider(url));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          // 只有当数据加载成功时，才显示“复制”按钮
          if (asyncContent.hasValue)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "复制全部",
              onPressed: () {
                final text = asyncContent.value!;
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板')),
                );
              },
            ),
        ],
      ),
      body: asyncContent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "无法加载文件\n$err",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(textContentProvider(url)),
                  icon: const Icon(Icons.refresh),
                  label: const Text("重试"),
                ),
              ],
            ),
          ),
        ),
        data: (text) {
          if (text.isEmpty) {
            return const Center(child: Text("文件内容为空"));
          }

          return SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace', // 使用等宽字体，对字幕/代码更友好
                  fontSize: 14,
                  height: 1.5, // 增加行高，阅读更舒适
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}