import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

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
            padding: const EdgeInsets.all(24.0),
            child: FileNodeBrowser(
              work: Work(),
              rootNodes: nodes,
              height: 500,
            ),
          );
        },
      ),
    );
  }
}
