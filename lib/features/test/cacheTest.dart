import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../album/presentation/viewmodel/provider/audio_file_provider.dart';

class WorkDetailTestPage extends ConsumerStatefulWidget {
  const WorkDetailTestPage({super.key});

  @override
  ConsumerState<WorkDetailTestPage> createState() => _WorkDetailTestPageState();
}

class _WorkDetailTestPageState extends ConsumerState<WorkDetailTestPage> {
  final TextEditingController _controller = TextEditingController(text: "1476452");
  int? currentId;

  @override
  Widget build(BuildContext context) {
    final workId = currentId;

    final asyncValue = workId == null
        ? null
        : ref.watch(workDetailProvider(workId)); // 关键调用

    return Scaffold(
      appBar: AppBar(title: const Text("WorkDetailProvider 测试")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "输入 Work ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentId = int.tryParse(_controller.text);
                });
              },
              child: const Text("加载 Work"),
            ),
            const SizedBox(height: 20),

            if (asyncValue == null)
              const Text("请输入 ID 后点击加载")
            else
              Expanded(
                child: asyncValue.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      "加载失败：$err",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (Work work) => _buildWorkInfo(work),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfo(Work work) {
    return ListView(
      children: [
        Text("作品ID: ${work.id}"),
        const SizedBox(height: 8),
        Text("标题: ${work.title ?? '无'}"),
        const SizedBox(height: 8),
        Text("作者: ${work.vas?.join(', ') ?? '无'}"),
        const SizedBox(height: 8),
        Text("封面: ${work.thumbnailCoverUrl ?? '无'}"),
        const SizedBox(height: 20),
        Text("Raw JSON:\n${work.toJson()}"),
      ],
    );
  }
}
