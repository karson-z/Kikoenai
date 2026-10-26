import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/widgets/common/manage_playlist_dialog.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/file_browser/provider/file_browser_edit_actions.dart';
import 'package:kikoenai/features/file_browser/widget/file_management_sheet.dart';
import 'package:kikoenai/features/player/provider/player_cloud_file_browser_controller.dart';
import 'package:kikoenai/features/player/provider/player_cloud_file_source_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/widget/other/player_cloud_file_sheet.dart';
import 'package:kikoenai/features/player/widget/other/player_more_options_sheet.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

const _origin = FileOrigin(
  kind: FileOriginKind.alist,
  connectionId: 'test-a',
  filePath: '/root/album/current.mp3',
  rootPath: '/root',
);
FileNode _node(String path, [NodeType type = NodeType.audio]) => FileNode(
  type: type,
  title: path.split('/').last,
  path: path,
  remoteId: path,
  source: NodeSource.asmrGay,
  siteId: 'asmr.gay',
  mediaStreamUrl: 'https://example.test/d$path?sign=keep',
  fileOrigin: _origin.atPath(path),
);
CloudDrivePageResult _page(List<FileNode> items, [int? total]) =>
    CloudDrivePageResult(items: items, totalCount: total ?? items.length);
BoundPlayerCloudSource _bound(_FakeSource fake, {void Function()? validate}) =>
    BoundPlayerCloudSource(
      delegate: fake,
      origin: _origin,
      label: 'Test source',
      validate: validate ?? () {},
    );

void main() {
  late Directory hiveDirectory;
  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'player_cloud_browser_',
    );
    Hive.init(hiveDirectory.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });
  test(
    'starts in parent directory and locates current file on later pages',
    () async {
      final fake = _FakeSource(
        (path, page) async => page == 1
            ? _page([_node('$path/other.mp3')], 2)
            : _page([_node(_origin.filePath)], 2),
      );
      final controller = PlayerCloudFileBrowserController(_bound(fake));
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.path, '/root/album');
      expect(controller.containsCurrentFile, isFalse);
      expect(fake.requests.length, 1);
      await controller.locateCurrentFile();
      expect(controller.containsCurrentFile, isTrue);
      expect(fake.requests, [('/root/album', 1), ('/root/album', 2)]);
    },
  );

  test(
    'outdated refresh and paging cannot overwrite a different directory',
    () async {
      final old = Completer<CloudDrivePageResult>();
      final fake = _FakeSource(
        (path, page) => path == '/root/album'
            ? old.future
            : Future.value(_page([_node('$path/new.mp3')])),
      );
      final controller = PlayerCloudFileBrowserController(_bound(fake));
      addTearDown(controller.dispose);
      final request = controller.refresh();
      await controller.navigate('/root/next');
      old.complete(_page([_node('/root/album/stale.mp3')]));
      await request;
      expect(controller.path, '/root/next');
      expect(controller.state.nodes.single.title, 'new.mp3');
      await controller.navigate('/outside');
      expect(controller.path, '/root/next');
    },
  );

  test(
    'each browser owns sort and selection; all-loaded does not select later pages',
    () async {
      final fake = _FakeSource(
        (path, page) async => _page([_node('$path/$page.mp3')], 2),
      );
      final a = PlayerCloudFileBrowserController(_bound(fake));
      final b = PlayerCloudFileBrowserController(_bound(fake));
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await a.refresh();
      await b.refresh();
      a.toggleAllLoaded();
      a.setSort(CloudDriveSort.nameDesc);
      await a.loadMore();
      expect(a.selected.length, 1);
      expect(a.allLoadedSelected, isFalse);
      expect(b.selected, isEmpty);
      expect(b.state.sort, CloudDriveSort.defaultSort);
    },
  );

  test(
    'pagination with duplicate pages terminates instead of locating forever',
    () async {
      final fake = _FakeSource(
        (path, page) async => _page([_node('$path/other.mp3')], 200),
      );
      final controller = PlayerCloudFileBrowserController(_bound(fake));
      addTearDown(controller.dispose);
      await controller.refresh();
      await controller.locateCurrentFile();
      expect(controller.state.hasMore, isFalse);
      expect(fake.requests.length, 2);
    },
  );

  test(
    'bound source validates connection before and after I/O and enforces root',
    () async {
      var valid = true;
      final result = Completer<CloudDrivePageResult>();
      final fake = _FakeSource((_, __) => result.future);
      final source = _bound(
        fake,
        validate: () {
          if (!valid) {
            throw const PlayerCloudSourceException('connection changed');
          }
        },
      );
      await expectLater(
        source.list(path: '/private', page: 1, pageSize: 50),
        throwsA(isA<PlayerCloudSourceException>()),
      );
      expect(fake.requests, isEmpty);
      final pending = source.list(path: '/root/album', page: 1, pageSize: 50);
      valid = false;
      result.complete(_page([_node(_origin.filePath)]));
      await expectLater(pending, throwsA(isA<PlayerCloudSourceException>()));
    },
  );

  test(
    'recursive collection handles cycles, audio/video and cancellation',
    () async {
      final fake = _FakeSource(
        (path, _) async => _page([
          _node('$path/a.mp3'),
          _node('$path/v.mp4', NodeType.video),
          _node(path, NodeType.folder),
        ]),
      );
      final collection = await FileBrowserEditActions.collectCloudPlayable(
        source: _bound(fake),
        selected: [_node('/root/album', NodeType.folder)],
      );
      expect(collection.files.map((file) => file.type), [
        NodeType.audio,
        NodeType.video,
      ]);
      expect(fake.requests.length, 1);
      final cancelled = await FileBrowserEditActions.collectCloudPlayable(
        source: _bound(fake),
        selected: [_node('/root/album', NodeType.folder)],
        isCancelled: () => true,
      );
      expect(cancelled.cancelled, isTrue);
      expect(fake.requests.length, 1);
    },
  );

  test('failed pagination can retry without losing loaded files', () async {
    var fail = true;
    final fake = _FakeSource((path, page) async {
      if (page == 1) return _page([_node('$path/one.mp3')], 2);
      if (fail) throw StateError('offline');
      return _page([_node(_origin.filePath)], 2);
    });
    final controller = PlayerCloudFileBrowserController(_bound(fake));
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.loadMore();
    expect(controller.state.nodes, hasLength(1));
    expect(controller.state.currentPage, 1);
    expect(controller.state.errorMessage, isNotNull);
    fail = false;
    await controller.loadMore();
    expect(controller.state.nodes, hasLength(2));
    expect(controller.containsCurrentFile, isTrue);
    expect(controller.state.errorMessage, isNull);
  });

  test('late response after disposal does not notify listeners', () async {
    final result = Completer<CloudDrivePageResult>();
    final controller = PlayerCloudFileBrowserController(
      _bound(_FakeSource((_, __) => result.future)),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);
    final pending = controller.refresh();
    controller.dispose();
    result.complete(_page([_node(_origin.filePath)]));
    await pending;
    expect(notifications, 1);
  });

  testWidgets('cancelling collection keeps selection and the browser open', (
    tester,
  ) async {
    final listing = Completer<CloudDrivePageResult>();
    final folder = _node('/root/album/folder', NodeType.folder);
    final fake = _FakeSource(
      (path, _) =>
          path == folder.path ? listing.future : Future.value(_page([folder])),
    );
    final player = _RecordingPlayer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerControllerProvider.overrideWith(() => player)],
        child: MaterialApp(
          navigatorObservers: [KikoenaiDialog.observer],
          home: Scaffold(
            body: PlayerCloudFileBrowser(
              source: _bound(fake),
              track: PlaybackItem.fromFileNode(_node(_origin.filePath)),
              onBack: () {},
              onManageSource: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('递归'), findsNothing);
    final row = find.ancestor(
      of: find.text('folder'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.byType(Checkbox)));
    await tester.pump();
    await tester.tap(find.text('加入队列'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('取消收集'));
    await tester.pump();
    expect(find.text('正在取消…'), findsOneWidget);
    listing.complete(_page([_node('/root/album/folder/file.mp3')]));
    await tester.pumpAndSettle();
    expect(player.added, isEmpty);
    expect(find.text('加入播放队列'), findsNothing);
    expect(find.text('已选 1 项'), findsOneWidget);
    expect(find.byType(PlayerCloudFileBrowser), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue failure preserves selection for retry', (tester) async {
    final player = _RecordingPlayer()..failAdding = true;
    final fake = _FakeSource((_, __) async => _page([_node(_origin.filePath)]));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerControllerProvider.overrideWith(() => player)],
        child: MaterialApp(
          navigatorObservers: [KikoenaiDialog.observer],
          home: Scaffold(
            body: PlayerCloudFileBrowser(
              source: _bound(fake),
              track: PlaybackItem.fromFileNode(_node(_origin.filePath)),
              onBack: () {},
              onManageSource: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('current.mp3'));
    await tester.pump();
    for (final fail in [true, false]) {
      player.failAdding = fail;
      await tester.tap(find.text('加入队列'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入'));
      await tester.pumpAndSettle();
      expect(find.text(fail ? '已选 1 项' : '已选 0 项'), findsOneWidget);
    }
    expect(player.added, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('directory error in real modal can retry at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var fail = true;
      final fake = _FakeSource((path, _) async {
        if (fail) throw const PlayerCloudSourceException('目录暂时不可用');
        return _page([_node(_origin.filePath)]);
      });
      final track = PlaybackItem.fromFileNode(_node(_origin.filePath));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith(_RecordingPlayer.new),
            playerCloudFileSourceProvider.overrideWith(
              (ref, args) async => _bound(fake),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [KikoenaiDialog.observer],
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showMoreOptions(context, ref, track),
                  child: const Text('打开更多'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开更多'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('文件管理'));
      await tester.pumpAndSettle();
      expect(find.text('目录暂时不可用'), findsOneWidget);
      expect(tester.takeException(), isNull);
      fail = false;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('current.mp3'), findsOneWidget);
      expect(find.text('目录暂时不可用'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'real player more sheet opens cloud file manager and returns at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fake = _FakeSource(
          (_, __) async => _page([_node(_origin.filePath)]),
        );
        final track = PlaybackItem.fromFileNode(_node(_origin.filePath));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playerControllerProvider.overrideWith(_RecordingPlayer.new),
              playerCloudFileSourceProvider.overrideWith(
                (ref, args) async => _bound(fake),
              ),
            ],
            child: MaterialApp(
              navigatorObservers: [KikoenaiDialog.observer],
              home: Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => showMoreOptions(context, ref, track),
                      child: const Text('打开更多'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开更多'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('文件管理'));
        await tester.pumpAndSettle();
        expect(find.byType(PlayerCloudFileBrowser), findsOneWidget);
        expect(find.byType(FileManagementSheet), findsOneWidget);
        expect(find.text('current.mp3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final requests = fake.requests.length;
        await tester.tap(find.byTooltip('刷新目录'));
        await tester.pumpAndSettle();
        expect(fake.requests.length, requests + 1);
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(find.text('文件管理'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'browser selects unassociated video and keeps page after adding at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final video = _node('/root/album/video.mp4', NodeType.video);
        final fake = _FakeSource(
          (path, _) async => _page([_node(_origin.filePath), video]),
        );
        final player = _RecordingPlayer();
        final track = PlaybackItem.fromFileNode(_node(_origin.filePath));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [playerControllerProvider.overrideWith(() => player)],
            child: MaterialApp(
              navigatorObservers: [KikoenaiDialog.observer],
              home: Scaffold(
                body: PlayerCloudFileBrowser(
                  source: _bound(fake),
                  track: track,
                  onBack: () {},
                  onManageSource: () async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('正在播放'), findsOneWidget);
        await tester.tap(find.text('video.mp4'));
        await tester.pump();
        await tester.tap(find.text('加入队列'));
        await tester.pumpAndSettle();
        expect(find.text('正在收集媒体'), findsNothing);
        expect(find.text('加入播放队列'), findsOneWidget);
        await tester.tap(find.text('加入'));
        await tester.pumpAndSettle();
        expect(player.added.single.isVideo, isTrue);
        expect(player.added.single.workId, isNull);
        expect(player.added.single.fileOrigin, video.fileOrigin);
        expect(find.byType(PlayerCloudFileBrowser), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('existing local file tree adds video without work metadata', (
    tester,
  ) async {
    final player = _RecordingPlayer();
    final index = FileNodeLibraryIndex(
      flatNodes: [
        FileNode(
          type: NodeType.video,
          title: 'local.mp4',
          path: '/media/local.mp4',
          folderPath: '/media',
          source: NodeSource.local,
        ),
      ],
      rootPath: '/media',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith(() => player),
          allTasksProvider.overrideWith(_NoDownloads.new),
        ],
        child: MaterialApp(
          navigatorObservers: [KikoenaiDialog.observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    FileTreeWoltSheet.show(context: context, index: index),
                child: const Text('本地文件管理'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('本地文件管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('local.mp4'));
    await tester.pump();
    await tester.tap(find.text('加入队列'));
    await tester.pumpAndSettle();
    expect(player.added.single.isVideo, isTrue);
    expect(player.added.single.source, NodeSource.local);
    expect(tester.takeException(), isNull);
  });
}

class _NoDownloads extends AllTasksNotifier {
  @override
  Future<List<TaskRecord>> build() async => [];
}

class _RecordingPlayer extends PlayerController {
  final added = <PlaybackItem>[];
  bool failAdding = false;
  @override
  AppPlayerState build() => const AppPlayerState();
  @override
  Future<void> addPlaybackItems(List<PlaybackItem> items) async =>
      added.addAll(items);

  @override
  Future<void> addAll(List<MediaItem> items) async {
    if (failAdding) throw StateError('queue unavailable');
    added.addAll(items.map(PlaybackItem.fromMediaItem));
  }
}

class _FakeSource implements CloudDriveSource {
  _FakeSource(this.load);
  final Future<CloudDrivePageResult> Function(String, int) load;
  final requests = <(String, int)>[];
  @override
  String get id => 'fake';
  @override
  String get label => 'fake';
  @override
  NodeSource get nodeSource => NodeSource.asmrGay;
  @override
  bool get supportsPagination => true;
  @override
  bool get supportsRemoteSearch => false;
  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) {
    requests.add((path, page));
    return load(path, page);
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) => list(path: path, page: page, pageSize: pageSize);
  @override
  String describeError(Object error) => error.toString();
}
