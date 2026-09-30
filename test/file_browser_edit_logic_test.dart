import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/file_scanner_worker.dart';
import 'package:kikoenai/core/service/file/local_batch_rename.dart';
import 'package:kikoenai/core/service/file/local_scan_exclusions.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/core/utils/scraper/scraper_selection.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _node(String path, {bool folder = false, int? workId}) => FileNode(
      type: folder ? NodeType.folder : NodeType.audio,
      title: path.split('/').last,
      path: path,
      workId: workId,
      source: NodeSource.localWork,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selection uses folder name and deduplicates works across paths', () {
    final nodes = [
      _node('/root/RJ01234567', folder: true, workId: 7654321),
      _node('/other/RJ01234567.mp3'),
      _node('/root/other', folder: true, workId: 1234567),
      _node('/root/RJ07654321.mp3'),
      _node('/root/XRJ01111111.mp3', workId: 1111111),
      _node('/root/RJ01234567/RJ05555555.mp3'),
    ];
    final selected = eligibleScraperNodes(
      nodes,
      const ScraperQueueState(),
      hasWork: (_) => false,
    );
    expect(selected.map((node) => node.workId), [1234567, 7654321, 5555555]);
    expect(selected.first.title, 'RJ01234567');
    expect(
        eligibleScraperNodes(
            nodes,
            ScraperQueueState(
              pending: [selected.first],
            ),
            hasWork: (_) => false).map((node) => node.workId),
        [7654321, 5555555]);
  });

  test('queue rejects another path for an already pending work', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final queue = container.read(scraperQueueProvider.notifier);
    await queue.addTasks([
      _node('/first/RJ01234567.mp3', workId: 1234567),
      _node('/second/RJ01234567.mp3', workId: 1234567),
    ]);
    expect(container.read(scraperQueueProvider).pending.length, 1);
    await queue.addTasks([_node('/third/RJ01234567.mp3', workId: 1234567)]);
    expect(container.read(scraperQueueProvider).pending.length, 1);
  });

  test('exclusion rules are scoped by target and match path segments',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('kiko_exclusion_test');
    addTearDown(() async {
      await AppStorage.settingsBox.close();
      await temporary.delete(recursive: true);
    });
    Hive.init(temporary.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('edit_rules');
    const exclusions = LocalScanExclusions();
    await exclusions.add(ScanMode.audio, '/root', ['/root/Folder']);
    expect(exclusions.isExcluded(ScanMode.audio, '/root', '/root/Folder/a.mp3'),
        isTrue);
    expect(exclusions.isExcluded(ScanMode.video, '/root', '/root/Folder/a.mp4'),
        isFalse);
    expect(
        exclusions.isExcluded(ScanMode.audio, '/other', '/root/Folder/a.mp3'),
        isFalse);
    expect(
        LocalScanExclusions.containsPath('/root/Folder', '/root/Folder2/a.mp3'),
        isFalse);
    expect(
        LocalScanExclusions.containsPath(
            '/root/a.zip/sub', '/root/a.zip/sub/a.srt'),
        isTrue);
    await exclusions.remove(ScanMode.audio, '/root', ['/root/Folder']);
    expect(exclusions.getRules(ScanMode.audio, '/root'), isEmpty);
  });

  test('worker skips excluded folder before indexing files', () async {
    final temporary = await Directory.systemTemp.createTemp('kiko_scan_test');
    addTearDown(() => temporary.delete(recursive: true));
    await Directory('${temporary.path}/skip').create();
    await Directory('${temporary.path}/keep').create();
    await File('${temporary.path}/skip/RJ01234567.mp3').writeAsString('a');
    await File('${temporary.path}/keep/RJ07654321.mp3').writeAsString('b');
    final result = await FileScanWorker().start(
      path: temporary.path,
      extensions: {'.mp3'},
      parsedWorkIds: {},
      excludedPaths: ['${temporary.path}/skip'],
    );
    expect(result.map((node) => node.title), ['RJ07654321.mp3']);
  });

  test('rename validates collisions and preserves extension', () async {
    final temporary = await Directory.systemTemp.createTemp('kiko_rename_test');
    Hive.init(temporary.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('rename_rules');
    addTearDown(() async {
      await AppStorage.settingsBox.close();
      await temporary.delete(recursive: true);
    });
    final first = File('${temporary.path}/one.mp3');
    final second = File('${temporary.path}/two.mp3');
    await first.writeAsString('one');
    await second.writeAsString('two');
    const service = LocalBatchRename();
    final node = _node(first.path);
    expect(service.validate([RenameProposal(node, 'new.txt')]).values.single,
        '文件扩展名不可修改');
    expect(service.validate([RenameProposal(node, 'two.mp3')]).values.single,
        '目标路径已存在');
    final proposal = RenameProposal(node, 'new.mp3');
    expect(service.validate([proposal]), isEmpty);
    final result = await service.execute([proposal]);
    expect(result.succeeded, [proposal]);
    expect(await File('${temporary.path}/new.mp3').readAsString(), 'one');
  });

  test('rename reports partial success when a later source disappears', () async {
    final temporary = await Directory.systemTemp.createTemp('kiko_rename_partial');
    Hive.init(temporary.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('partial_rules');
    addTearDown(() async {
      await AppStorage.settingsBox.close();
      await temporary.delete(recursive: true);
    });
    final folder = await Directory('${temporary.path}/album').create();
    final song = File('${folder.path}/song.mp3');
    await song.writeAsString('audio');
    final result = await const LocalBatchRename().execute([
      RenameProposal(_node(folder.path, folder: true), 'album_new'),
      RenameProposal(_node(song.path), 'song_new.mp3'),
    ]);
    expect(result.succeeded.length, 1);
    expect(result.failed.length, 1);
    expect(await File('${temporary.path}/album_new/song.mp3').exists(), isTrue);
  });
}
