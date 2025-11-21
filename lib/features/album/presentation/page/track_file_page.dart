import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/global_exception.dart';
import '../viewmodel/provider/audio_file_provider.dart';
import '../widget/file_box.dart';

class FileNodeTestPage extends ConsumerWidget {
  const FileNodeTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(trackFileNodeProvider(1431624));

    return Scaffold(
      appBar: AppBar(title: const Text('文件浏览器')),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          if (err is GlobalException) {
            return Center(
              child: Text(
                "GlobalException: ${err.message}\ncode=${err.code}",
              ),
            );
          }
          return Center(child: Text("Other error: $err"));
        },
        data: (nodes) {
          // ✅ 直接把 provider 的 data 传给组件
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: FileNodeBrowser(
              rootNodes: nodes,
              onFileTap: (node) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('点击文件: ${node.title}')),
                );
              }, height: 500,
            ),
          );
        },
      ),
    );
  }
}
