import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/file/file_scanner_service.dart';
import 'package:kikoenai/core/service/file/file_scanner_worker.dart';

import 'package:kikoenai/core/service/file/file_tree_builder.dart';

void main() {
  group('Performance Benchmark: Full Pipeline (Scan + Build Tree)', () {
    late Directory tempRoot;
    const int totalFolders = 1000;
    const int filesPerFolder = 1000;
    const int expectedFiles = totalFolders * filesPerFolder;

    setUpAll(() async {
      // [Arrange] 准备 10,000 个物理文件及对应的层级目录
      tempRoot = await Directory.systemTemp.createTemp('pipeline_benchmark_');

      for (int i = 0; i < totalFolders; i++) {
        final dir = Directory('${tempRoot.path}/RJ${200000 + i}');
        await dir.create();
        for (int j = 0; j < filesPerFolder; j++) {
          final file = File('${dir.path}/track_$j.mp3');
          await file.create();
        }
      }
    });

    tearDownAll(() async {
      // 清理测试产生的临时文件
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('Scan and build tree for $expectedFiles files', () async {
      // [Arrange] 初始化核心组件与计时器
      final worker = FileScanWorker();
      final treeBuilder = IncrementalTreeBuilder();

      // 必须为 builder 设置正确的根路径，否则节点会被过滤
      treeBuilder.setRootPath(tempRoot.path);

      final stopwatch = Stopwatch();
      int receivedChunks = 0;
      int lastScannedCount = 0;

      // [Act] 启动全链路计时
      stopwatch.start();

      final resultStream = worker.start(
        path: tempRoot.path,
        extensions: {'.mp3'},
        scanMode: ScanMode.audio,
        scanArchives: false,
        parsedRjCodes: {},
      );

      // 实时消费 Worker 传回的批次数据，并交由 Builder 构建树
      await for (final batch in resultStream) {
        receivedChunks++;
        lastScannedCount = batch.scannedCount;
        treeBuilder.mergeChunk(batch.nodes);
      }

      stopwatch.stop();
      worker.dispose();

      // [Assert] 验证树的构建结果是否符合预期
      // 根目录下应该只有我们创建的 totalFolders 个 RJ 文件夹
      expect(treeBuilder.roots.length, totalFolders);

      // 随机抽查一个文件夹，验证其内部文件数量
      final sampleFolder = treeBuilder.roots.first;
      expect(sampleFolder.isFolder, isTrue);
      expect(sampleFolder.children?.length, filesPerFolder);
      expect(lastScannedCount, expectedFiles);

      // 输出性能报告
      print('--- 全链路性能基准测试报告 ---');
      print('目标物理文件数: $expectedFiles');
      print('构建生成的根文件夹数: ${treeBuilder.roots.length}');
      print('处理的批次数量: $receivedChunks');
      print('----------------------------');
      print('全链路总耗时 (I/O + 通信 + 树构建): ${stopwatch.elapsedMilliseconds} ms');
      print('平均吞吐量: ${(expectedFiles / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(0)} files/sec');
      print('----------------------------');
    });
  });
}
