import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/download/download_service.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/common/manage_playlist_dialog.dart';
import 'package:kikoenai/core/widgets/common/custom_bottom_type.dart';
import 'package:kikoenai/core/widgets/common/custom_side_sheet_type.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';
import 'package:kikoenai/features/file_browser/widget/file_management_sheet.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_option.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

FileNode _file(
  String path, {
  bool remote = false,
  String? hash,
  double? duration,
}) => FileNode(
  type: path.endsWith('.mp4') ? NodeType.video : NodeType.audio,
  title: path.split('/').last,
  path: path,
  hash: hash,
  folderPath: NodeFolder.dirName(path),
  source: remote ? NodeSource.asmrServer : NodeSource.local,
  mediaStreamUrl: remote ? 'https://example.test$path?sign=keep' : path,
  mediaDownloadUrl: remote ? 'https://example.test$path?sign=keep' : null,
  duration: duration,
  size: 1024,
);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));
Finder _checkbox(String title) =>
    find.descendant(of: _row(title), matching: find.byType(Checkbox));

class _Player extends PlayerController {
  final items = <PlaybackItem>[];
  bool fail = false;
  @override
  AppPlayerState build() => const AppPlayerState();
  @override
  Future<void> addAll(List<MediaItem> media) async {
    if (fail) throw StateError('failed queue');
    items.addAll(media.map(PlaybackItem.fromMediaItem));
  }
}

class _Tasks extends AllTasksNotifier {
  _Tasks([this.records = const []]);
  final List<TaskRecord> records;
  @override
  Future<List<TaskRecord>> build() async => records;
}

class _MemorySort extends FileSortNotifier {
  @override
  FileSortOption build() => FileSortOption.defaultOption;
  @override
  void update(FileSortOption option) => state = option;
}

class _Downloads implements DownloadService {
  List<FileNode> files = [];
  FileNodeLibraryIndex? index;
  String? title;
  dynamic metadata;
  bool fail = false;
  @override
  Future<void> enqueueBatch({
    required List<FileNode> selectedFiles,
    required FileNodeLibraryIndex index,
    required String title,
    dynamic metaData,
  }) async {
    if (fail) throw StateError('failed download');
    files = selectedFiles;
    this.index = index;
    this.title = title;
    metadata = metaData;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _mount(
  WidgetTester tester,
  FileNodeLibraryIndex index, {
  Work? work,
  PlaybackItem? track,
  _Player? player,
  _Downloads? downloads,
  List<TaskRecord> tasks = const [],
  bool nested = false,
  bool memorySort = false,
  double textScale = 1,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerControllerProvider.overrideWith(() => player ?? _Player()),
        allTasksProvider.overrideWith(() => _Tasks(tasks)),
        if (memorySort) fileSortProvider.overrideWith(_MemorySort.new),
        if (downloads != null)
          downloadServiceProvider.overrideWithValue(downloads),
      ],
      child: MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        navigatorObservers: [KikoenaiDialog.observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('打开文件'),
              onPressed: () {
                if (nested) {
                  WoltModalSheet.show<void>(
                    context: context,
                    pageListBuilder: (context) => [
                      WoltModalSheetPage(
                        child: Builder(
                          builder: (context) => TextButton(
                            onPressed: () {
                              WoltModalSheet.of(context).addPage(
                                FileTreeWoltSheet.buildPage(
                                  context,
                                  index: index,
                                  work: work,
                                  isFirstPage: false,
                                  track: track,
                                ),
                              );
                              WoltModalSheet.of(context).showNext();
                            },
                            child: const Text('文件管理入口'),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  FileTreeWoltSheet.show(
                    context: context,
                    index: index,
                    work: work,
                  );
                }
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开文件'));
  await tester.pumpAndSettle();
  if (nested) {
    await tester.tap(find.text('文件管理入口'));
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('unified_files_');
    Hive.init(directory.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });
  tearDown(() async => AppStorage.settingsBox.clear());
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets(
      'iOS header buttons receive taps across their full touch area at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var back = 0;
        var refresh = 0;
        var settings = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => WoltModalSheet.show<void>(
                    context: context,
                    modalTypeBuilder: (_) => size.width < 500
                        ? const CustomBottomType()
                        : const CustomSideSheetType(),
                    pageListBuilder: (_) => [
                      buildFileManagementPage(
                        Column(
                          children: [
                            FileManagementHeader(
                              title: '文件管理',
                              onBack: () => back++,
                              onRefresh: () => refresh++,
                              onManageSource: () => settings++,
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开'));
        await tester.pumpAndSettle();
        for (final tooltip in ['返回', '刷新目录', '来源设置']) {
          final button = find.byTooltip(tooltip);
          final rect = tester.getRect(button);
          await tester.tapAt(Offset(rect.center.dx, rect.top + 4));
          await tester.pump();
          await tester.tap(button);
          await tester.pump();
          await tester.tapAt(Offset(rect.center.dx, rect.bottom - 4));
          await tester.pump();
        }
        expect(back, 3);
        expect(refresh, 3);
        expect(settings, 3);
        expect(tester.takeException(), isNull);
        if (size.width < 500) {
          final header = tester.getRect(find.byType(FileManagementHeader));
          await tester.flingFrom(
            Offset(size.width / 2, header.top - 24),
            const Offset(0, 400),
            1200,
          );
          await tester.pumpAndSettle();
          expect(find.byType(FileManagementHeader), findsNothing);
        }
      },
    );
  }

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets(
      'indexed files use the shared sheet and preserve folder selection at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final index = FileNodeLibraryIndex(
          flatNodes: [
            _file('/media/album/one.mp3'),
            _file('/media/album/two.mp4'),
            _file('/media/other.mp3'),
          ],
          rootPath: '/media',
        );
        await _mount(tester, index);
        expect(find.byType(FileManagementSheet), findsOneWidget);
        await tester.tap(find.text('album'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('one.mp3'));
        await tester.pump();
        expect(find.text('已选 1 项'), findsOneWidget);
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(_checkbox('album')).value, isNull);
        await tester.tap(_checkbox('album'));
        await tester.pump();
        expect(find.text('已选 2 项'), findsOneWidget);
        final sheet = tester.widget<FileManagementSheet>(
          find.byType(FileManagementSheet),
        );
        sheet.onToggleAll!();
        await tester.pump();
        expect(find.text('已选 3 项'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('打开文件'));
        await tester.pumpAndSettle();
        expect(find.text('已选 0 项'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('indexed popup retains numeric-title and duration sorts', (
    tester,
  ) async {
    final index = FileNodeLibraryIndex(
      flatNodes: [
        _file('/media/10.mp3', duration: 20),
        _file('/media/2.mp3', duration: 10),
      ],
      rootPath: '/media',
    );
    await _mount(tester, index, memorySort: true);
    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('标题序号 · 升序'));
    await tester.pumpAndSettle();
    expect(index.currentChildren.map((node) => node.title), [
      '2.mp3',
      '10.mp3',
    ]);
    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('时长 · 降序'));
    await tester.pumpAndSettle();
    expect(index.currentChildren.map((node) => node.title), [
      '10.mp3',
      '2.mp3',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared modal fits a small phone with large text and dark theme',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final index = FileNodeLibraryIndex(
        flatNodes: [_file('/work/track.mp3', remote: true)],
        rootPath: '/work',
      );
      await _mount(
        tester,
        index,
        work: const Work(id: 42, title: 'Test work'),
        textScale: 1.6,
        dark: true,
      );
      expect(find.byType(FileManagementSheet), findsOneWidget);
      expect(find.byTooltip('下载'), findsOneWidget);
      expect(find.text('加入队列'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'work download keeps metadata, skips completed files and preserves selection on error',
    (tester) async {
      final pending = _file('/work/pending.mp3', remote: true, hash: 'pending');
      final done = _file('/work/done.mp3', remote: true, hash: 'done');
      final index = FileNodeLibraryIndex(
        flatNodes: [pending, done],
        rootPath: '/work',
      );
      final downloads = _Downloads()..fail = true;
      final task = DownloadTask(
        taskId: 'done',
        url: 'https://example.test/done.mp3',
      );
      await _mount(
        tester,
        index,
        work: const Work(id: 42, title: 'Test work'),
        downloads: downloads,
        tasks: [TaskRecord(task, TaskStatus.complete, 1, 1024, null)],
      );
      expect(find.textContaining('已下载'), findsOneWidget);
      var sheet = tester.widget<FileManagementSheet>(
        find.byType(FileManagementSheet),
      );
      expect(sheet.onDownload, isNull);
      sheet.onToggleAll!();
      await tester.pump();
      await tester.tap(find.byTooltip('下载'));
      await tester.pumpAndSettle();
      expect(find.text('已选 2 项'), findsOneWidget);
      downloads.fail = false;
      await tester.tap(find.byTooltip('下载'));
      await tester.pumpAndSettle();
      expect(downloads.files.single.hash, 'pending');
      expect(downloads.files.single.mediaDownloadUrl, contains('?sign=keep'));
      expect(downloads.index, same(index));
      expect(downloads.title, 'Test work');
      expect(downloads.metadata['id'], 42);
      expect(find.byType(FileManagementSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'work queue keeps metadata and failure leaves selection available',
    (tester) async {
      final player = _Player()..fail = true;
      final index = FileNodeLibraryIndex(
        flatNodes: [_file('/work/video.mp4', remote: true)],
        rootPath: '/work',
      );
      await _mount(
        tester,
        index,
        work: const Work(id: 42, title: 'Test work'),
        player: player,
      );
      await tester.tap(find.text('video.mp4'));
      await tester.pump();
      await tester.tap(find.text('加入队列'));
      await tester.pumpAndSettle();
      expect(find.text('已选 1 项'), findsOneWidget);
      player.fail = false;
      await tester.tap(find.text('加入队列'));
      await tester.pumpAndSettle();
      expect(player.items.single.workId, 42);
      expect(player.items.single.isVideo, isTrue);
      expect(player.items.single.url, contains('?sign=keep'));
      expect(find.byType(FileManagementSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested index page locates current file and returns to more menu',
    (tester) async {
      final file = _file('/media/album/current.mp3');
      final index = FileNodeLibraryIndex(flatNodes: [file], rootPath: '/media')
        ..jumpToFilePath(file.path!);
      await _mount(
        tester,
        index,
        nested: true,
        track: PlaybackItem.fromFileNode(file),
      );
      expect(find.textContaining('正在播放'), findsOneWidget);
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(find.text('album'), findsOneWidget);
      await tester.tap(find.byTooltip('定位正在播放的文件'));
      await tester.pumpAndSettle();
      expect(find.text('current.mp3'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('文件管理入口'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
