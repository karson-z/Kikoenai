import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/service/file/work_association_index.dart';
import 'package:kikoenai/core/service/lyrics/search_lyrics_service.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _node({
  required NodeType type,
  required String title,
  required String path,
  String? folderPath,
  int? workId,
  NodeSource source = NodeSource.localSingle,
}) {
  return FileNode(
    type: type,
    title: title,
    path: path,
    folderPath: folderPath,
    rootPath: '/media',
    workId: workId,
    source: source,
  );
}

FileNode _audio(String folder, String title, {int? workId}) => _node(
  type: NodeType.audio,
  title: title,
  path: '$folder/$title',
  folderPath: folder,
  workId: workId,
);

FileNode _subtitle(String folder, String title) => _node(
  type: NodeType.text,
  title: title,
  path: '$folder/$title',
  folderPath: folder,
);

void main() {
  late Directory temp;
  const workFolder = '/media/library/circle/[RJ01234567] 作品';

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('kikoenai_work_assoc_');
    Hive.init(temp.path);
    Hive.registerAdapter(NodeTypeAdapter());
    Hive.registerAdapter(NodeStatusAdapter());
    Hive.registerAdapter(NodeSourceAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    Hive.registerAdapter(WorkAdapter());
    AppStorage.scannerBox = await Hive.openBox<FileNode>('scanner');
    AppStorage.scraperWorkBox = await Hive.openBox<Work>('scraper');
  });

  setUp(() async {
    await AppStorage.scannerBox.clear();
    await AppStorage.scraperWorkBox.clear();
    WorkAssociationIndex.instance.invalidate();
  });

  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  group('read-time path resolution', () {
    test('resolves the nearest RJ ancestor folder', () {
      final node = _audio('$workFolder/disc1', 'track01.mp3');

      expect(WorkAssociationIndex.instance.workIdForNode(node), 1234567);
      expect(
        WorkAssociationIndex.instance.workIdForPath('$workFolder/disc2'),
        1234567,
      );
      expect(
        WorkAssociationIndex.instance.workIdForPath('/media/library/circle'),
        isNull,
      );
    });

    test('falls back to a single-file work named with an RJ code', () {
      final node = _node(
        type: NodeType.audio,
        title: 'RJ09999999.mp3',
        path: '/media/library/RJ09999999.mp3',
        folderPath: '/media/library',
      );

      expect(WorkAssociationIndex.instance.workIdForNode(node), 9999999);
    });
  });

  group('lazy work index', () {
    test('maps scan-style nodes to works without persisted workId', () async {
      await AppStorage.scannerBox.putAll({
        'a': _audio('$workFolder/disc1', 'a.mp3'),
        'b': _audio('$workFolder/disc2', 'b.mp3'),
        'sub': _subtitle(workFolder, 'subtitle.srt'),
        'other': _audio('/media/library/no-rj', 'c.mp3'),
      });

      final files = WorkAssociationIndex.instance.filesForWork(1234567);
      expect(
        files.map((node) => node.title),
        containsAll(<String>['a.mp3', 'b.mp3', 'subtitle.srt']),
      );
      expect(files, hasLength(3));
      expect(WorkAssociationIndex.instance.filesForWork(1), isEmpty);
    });

    test('DL local lookup and local subtitle lookup use the index', () async {
      await AppStorage.scannerBox.putAll({
        'a': _audio('$workFolder/disc1', 'a.mp3'),
        'b': _audio('$workFolder/disc2', 'b.mp3'),
        'sub': _subtitle(workFolder, 'subtitle.srt'),
      });

      final index = FileScannerStorage().getWorkFileIndexLocally(1234567);
      expect(index, isNotNull);
      expect(index!.rootPath, workFolder);
      expect(
        index.nodeByPath.keys,
        contains('$workFolder/disc1/a.mp3'.toLowerCase()),
      );
      expect(
        index.nodeByPath.keys,
        contains('$workFolder/disc2/b.mp3'.toLowerCase()),
      );
      expect(FileScannerStorage().getWorkFileIndexLocally(1), isNull);

      final subtitles = SearchLyricsService.findSubtitleInLocalById(1234567);
      expect(subtitles.map((node) => node.title), ['subtitle.srt']);
    });

    test('rebuilds after the scanner box changes', () async {
      await AppStorage.scannerBox.put(
        'a',
        _audio('$workFolder/disc1', 'a.mp3'),
      );
      expect(WorkAssociationIndex.instance.filesForWork(1234567), hasLength(1));

      await AppStorage.scannerBox.put(
        'b',
        _audio('$workFolder/disc2', 'b.mp3'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(WorkAssociationIndex.instance.filesForWork(1234567), hasLength(2));
    });

    test('invalidates automatically when the box is cleared', () async {
      await AppStorage.scannerBox.put(
        'a',
        _audio('$workFolder/disc1', 'a.mp3'),
      );
      expect(WorkAssociationIndex.instance.filesForWork(1234567), hasLength(1));

      await AppStorage.scannerBox.clear();
      await Future<void>.delayed(Duration.zero);

      expect(WorkAssociationIndex.instance.filesForWork(1234567), isEmpty);
    });

    test('invalidates automatically after a node is deleted', () async {
      await AppStorage.scannerBox.putAll({
        'a': _audio('$workFolder/disc1', 'a.mp3'),
        'b': _audio('$workFolder/disc2', 'b.mp3'),
      });
      expect(WorkAssociationIndex.instance.filesForWork(1234567), hasLength(2));

      await AppStorage.scannerBox.delete('b');
      await Future<void>.delayed(Duration.zero);

      expect(WorkAssociationIndex.instance.filesForWork(1234567), hasLength(1));
    });

    test('parses Windows-style folder paths', () {
      final node = _node(
        type: NodeType.audio,
        title: 'a.mp3',
        path: r'C:\Media\[RJ01234567]\disc1\a.mp3',
        folderPath: r'C:\Media\[RJ01234567]\disc1',
      );

      expect(WorkAssociationIndex.instance.workIdForNode(node), 1234567);
      expect(
        WorkAssociationIndex.instance.workIdForPath(
          r'C:\Media\[RJ01234567]',
        ),
        1234567,
      );
    });

    test('merges cross-root files under their common ancestor', () async {
      await AppStorage.scannerBox.putAll({
        'audio': _audio('/media/audio/[RJ01234567]', 'a.mp3'),
        'sub': _subtitle('/media/subs/[RJ01234567]', 's.srt'),
      });

      final index = FileScannerStorage().getWorkFileIndexLocally(1234567);
      expect(index, isNotNull);
      expect(index!.rootPath, '/media');
      expect(index.nodeByPath, hasLength(2));
    });

    test('invalidate() drops cached path results too', () async {
      await AppStorage.scannerBox.put(
        'a',
        _audio('$workFolder/disc1', 'a.mp3'),
      );
      expect(WorkAssociationIndex.instance.workIdForPath(workFolder), 1234567);

      await AppStorage.scannerBox.clear();
      WorkAssociationIndex.instance.invalidate();

      expect(
        WorkAssociationIndex.instance.workIdForPath(workFolder),
        1234567,
        reason: 'path parsing is independent from the scanner box',
      );
      expect(WorkAssociationIndex.instance.filesForWork(1234567), isEmpty);
    });
  });

  group('playback association', () {
    test('resolves work metadata without changing source or resume scope',
        () async {
      await AppStorage.scraperWorkBox.put(
        1234567,
        const Work(
          id: 1234567,
          title: '作品标题',
          mainCoverUrl: 'https://example.test/cover.jpg',
        ),
      );

      final items = FileBrowserEditActions.playbackItems([
        _audio('$workFolder/disc1', 'a.mp3'),
      ]);

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.workId, 1234567);
      expect(item.albumTitle, '作品标题');
      expect(item.coverUrl, 'https://example.test/cover.jpg');
      expect(item.source, NodeSource.localSingle);
      expect(item.scopeKey, 'single_${item.id}');
      expect(item.isLocal, isTrue);
    });

    test('keeps files without a known work unassociated', () {
      final items = FileBrowserEditActions.playbackItems([
        _audio('/media/library/no-rj', 'c.mp3'),
      ]);

      expect(items.single.workId, isNull);
      expect(items.single.source, NodeSource.localSingle);
    });

    test('honours an explicit workOf callback', () {
      final items = FileBrowserEditActions.playbackItems([
        _audio('/media/library/no-rj', 'c.mp3'),
      ], workOf: (node) => const Work(id: 42, title: 'injected'));

      expect(items.single.workId, 42);
      expect(items.single.albumTitle, 'injected');
      expect(items.single.source, NodeSource.localSingle);
      expect(items.single.scopeKey, 'single_${items.single.id}');
    });

    test('read-time parsing wins over a stale persisted workId', () async {
      await AppStorage.scraperWorkBox.put(
        1234567,
        const Work(id: 1234567, title: '新作品'),
      );
      await AppStorage.scraperWorkBox.put(
        999999,
        const Work(id: 999999, title: '旧作品'),
      );
      final staleNode = _audio(
        '$workFolder/disc1',
        'a.mp3',
        workId: 999999,
      );
      await AppStorage.scannerBox.put('a', staleNode);

      expect(WorkAssociationIndex.instance.workIdForNode(staleNode), 1234567);
      expect(
        WorkAssociationIndex.instance.filesForWork(1234567),
        hasLength(1),
      );
      expect(WorkAssociationIndex.instance.filesForWork(999999), isEmpty);

      final items = FileBrowserEditActions.playbackItems([staleNode]);
      expect(items.single.workId, 1234567);
      expect(items.single.albumTitle, '新作品');
    });

    test('resolves every file in a mixed directory independently', () async {
      await AppStorage.scraperWorkBox.put(
        1111111,
        const Work(id: 1111111, title: 'A'),
      );
      await AppStorage.scraperWorkBox.put(
        2222222,
        const Work(id: 2222222, title: 'B'),
      );

      final items = FileBrowserEditActions.playbackItems([
        _audio('/media/lib/A/[RJ01111111]', 'a.mp3'),
        _audio('/media/lib/B/[RJ02222222]', 'b.mp3'),
      ]);

      expect(items.map((item) => item.workId), [1111111, 2222222]);
      expect(items.map((item) => item.albumTitle), ['A', 'B']);
    });
  });
}
