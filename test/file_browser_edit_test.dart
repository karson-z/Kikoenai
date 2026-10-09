import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/local_media/model/local_media_exclusion.dart';
import 'package:kikoenai/features/local_media/provider/local_media_exclusion_store.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _node({
  required NodeType type,
  required String title,
  required String path,
  String? folderPath,
  int? workId,
}) {
  return FileNode(
    type: type,
    title: title,
    path: path,
    folderPath: folderPath,
    rootPath: '/media',
    workId: workId,
    source: NodeSource.localWork,
  );
}

void main() {
  group('parse candidates', () {
    test('keeps only unparsed RJ folders', () {
      final nodes = [
        _node(
          type: NodeType.folder,
          title: 'RJ0123456',
          path: '/media/RJ0123456',
          workId: 123456,
        ),
        _node(
          type: NodeType.folder,
          title: 'RJ0999999',
          path: '/media/RJ0999999',
          workId: 999999,
        ),
        _node(type: NodeType.audio, title: 'a.mp3', path: '/media/a.mp3'),
      ];

      final result = FileBrowserEditActions.parseCandidates(
        directoryNodes: nodes,
        parsedWorkIds: {123456},
        queue: const ScraperQueueState(),
      );

      expect(result.map((node) => node.workId), [999999]);
    });

    test('skips a work that is already queued', () {
      final folder = _node(
        type: NodeType.folder,
        title: 'RJ0123456',
        path: '/media/RJ0123456',
        workId: 123456,
      );

      final result = FileBrowserEditActions.parseCandidates(
        directoryNodes: [folder],
        parsedWorkIds: const {},
        queue: ScraperQueueState(pending: [folder]),
      );

      expect(result, isEmpty);
    });
  });

  group('local playback collection', () {
    test('includes files inside a selected folder and skips exclusions', () {
      final index = FileNodeLibraryIndex(
        flatNodes: [
          _node(
            type: NodeType.audio,
            title: 'keep.mp3',
            path: '/media/work/keep.mp3',
            folderPath: '/media/work',
          ),
          _node(
            type: NodeType.audio,
            title: 'skip.mp3',
            path: '/media/work/extra/skip.mp3',
            folderPath: '/media/work/extra',
          ),
          _node(
            type: NodeType.text,
            title: 'note.txt',
            path: '/media/work/note.txt',
            folderPath: '/media/work',
          ),
        ],
        rootPath: '/media',
      )..exclusions = {(relativePath: 'work/extra', isFolder: true)};

      final result = FileBrowserEditActions.collectLocalPlayable(
        index: index,
        selected: [
          _node(type: NodeType.folder, title: 'work', path: '/media/work'),
        ],
      );

      expect(result.map((node) => node.title), ['keep.mp3']);
    });
  });

  group('cloud playback collection', () {
    test('walks folders and reports a failed directory', () async {
      final source = _FakeCloudSource({
        '/selected': [
          _node(type: NodeType.audio, title: 'root.mp3', path: '/selected/root.mp3'),
          _node(type: NodeType.folder, title: 'nested', path: '/selected/nested'),
          _node(type: NodeType.folder, title: 'broken', path: '/selected/broken'),
        ],
        '/selected/nested': [
          _node(
            type: NodeType.video,
            title: 'clip.mp4',
            path: '/selected/nested/clip.mp4',
          ),
        ],
      }, failingPaths: {'/selected/broken'});

      final result = await FileBrowserEditActions.collectCloudPlayable(
        source: source,
        selected: [
          _node(type: NodeType.folder, title: 'selected', path: '/selected'),
        ],
      );

      expect(result.files.map((node) => node.title), ['root.mp3', 'clip.mp4']);
      expect(result.failedDirectories, 1);
    });
  });

  group('local exclusions', () {
    late Directory hiveDirectory;
    late Box<dynamic> box;

    setUp(() async {
      hiveDirectory = await Directory.systemTemp.createTemp('kikoenai_exclude_');
      Hive.init(hiveDirectory.path);
      box = await Hive.openBox<dynamic>(BoxNames.localMediaExclusions);
    });

    tearDown(() async {
      await Hive.close();
      await hiveDirectory.delete(recursive: true);
    });

    test('stores entries by scan root and matches descendants', () async {
      final store = LocalMediaExclusionStore(box);
      await store.addAll([
        const LocalMediaExclusion(
          rootPath: '/media',
          relativePath: 'extra',
          isFolder: true,
        ),
      ]);

      expect(
        LocalMediaExclusionStore.isExcluded(
          rootPath: '/media',
          absolutePath: '/media/extra/skip.mp3',
          isFolder: false,
          entries: store.readForRoot('/media'),
        ),
        isTrue,
      );
      expect(
        LocalMediaExclusionStore.isExcluded(
          rootPath: '/other',
          absolutePath: '/other/extra/skip.mp3',
          isFolder: false,
          entries: store.readForRoot('/media'),
        ),
        isFalse,
      );
    });

    test('does not match a folder that only shares a name prefix', () {
      const entry = LocalMediaExclusion(
        rootPath: '/media',
        relativePath: 'work',
        isFolder: true,
      );

      expect(
        LocalMediaExclusionStore.isExcluded(
          rootPath: '/media',
          absolutePath: '/media/workspace/a.mp3',
          isFolder: false,
          entries: const [entry],
        ),
        isFalse,
      );
    });
  });
}

class _FakeCloudSource implements CloudDriveSource {
  _FakeCloudSource(this.pages, {this.failingPaths = const {}});

  final Map<String, List<FileNode>> pages;
  final Set<String> failingPaths;

  @override
  String get id => 'fake';

  @override
  String get label => 'fake';

  @override
  NodeSource get nodeSource => NodeSource.cloudDrive;

  @override
  bool get supportsPagination => false;

  @override
  bool get supportsRemoteSearch => false;

  @override
  String describeError(Object error) => error.toString();

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    if (failingPaths.contains(path)) throw StateError('failed');
    final items = pages[path] ?? const <FileNode>[];
    return CloudDrivePageResult(items: items, totalCount: items.length);
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) {
    throw UnimplementedError();
  }
}
