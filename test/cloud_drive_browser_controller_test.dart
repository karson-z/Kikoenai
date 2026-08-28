import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/cloud_drive/provider/cloud_drive_browser_controller.dart';
import 'package:kikoenai/features/cloud_drive/provider/cloud_drive_source_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  test('AList mode paginates, deduplicates, and uses remote search', () async {
    final source = _FakeCloudDriveSource(
      supportsRemoteSearch: true,
      supportsPagination: true,
      pages: {
        1: [_folder('/folder'), _audio('/one.mp3')],
        2: [_audio('/one.mp3'), _audio('/two.mp3')],
      },
      totalCount: 3,
      searchItems: [_audio('/nested/result.mp3')],
    );
    final container = ProviderContainer(
      overrides: [cloudDriveSourceProvider.overrideWith((ref, mode) => source)],
    );
    addTearDown(container.dispose);
    const args = (mode: CloudDriveMode.alistApi, path: '/');
    final subscription = container.listen(
      cloudDriveBrowserControllerProvider(args),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final controller = container.read(
      cloudDriveBrowserControllerProvider(args).notifier,
    );

    await controller.loadInitial();
    expect(container.read(cloudDriveBrowserControllerProvider(args)).nodes, [
      isA<FileNode>().having((node) => node.path, 'path', '/folder'),
      isA<FileNode>().having((node) => node.path, 'path', '/one.mp3'),
    ]);

    await controller.loadMore();
    final pagedState = container.read(
      cloudDriveBrowserControllerProvider(args),
    );
    expect(pagedState.nodes.map((node) => node.path), [
      '/folder',
      '/one.mp3',
      '/two.mp3',
    ]);
    expect(pagedState.hasMore, isFalse);

    await controller.search('result');
    final searchState = container.read(
      cloudDriveBrowserControllerProvider(args),
    );
    expect(searchState.isSearchMode, isTrue);
    expect(searchState.visibleNodes.single.path, '/nested/result.mp3');
    expect(source.lastSearchPath, '/');
  });

  test('WebDAV mode filters and sorts the loaded directory locally', () async {
    final source = _FakeCloudDriveSource(
      supportsRemoteSearch: false,
      supportsPagination: false,
      pages: {
        1: [
          _audio('/Zulu.mp3', size: 8),
          _folder('/Folder'),
          _audio('/alpha.mp3', size: 2),
        ],
      },
      totalCount: 3,
    );
    final container = ProviderContainer(
      overrides: [cloudDriveSourceProvider.overrideWith((ref, mode) => source)],
    );
    addTearDown(container.dispose);
    const args = (mode: CloudDriveMode.webDav, path: '/');
    final subscription = container.listen(
      cloudDriveBrowserControllerProvider(args),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final controller = container.read(
      cloudDriveBrowserControllerProvider(args).notifier,
    );

    await controller.loadInitial();
    controller.updateLocalSearch('MP3');
    controller.setSort(CloudDriveSort.sizeAsc);
    var state = container.read(cloudDriveBrowserControllerProvider(args));
    expect(state.visibleNodes.map((node) => node.title), [
      'alpha.mp3',
      'Zulu.mp3',
    ]);
    expect(source.searchCallCount, 0);

    controller.updateLocalSearch('');
    controller.setScope(CloudDriveScope.folders);
    state = container.read(cloudDriveBrowserControllerProvider(args));
    expect(state.visibleNodes.single.path, '/Folder');
    expect(state.hasMore, isFalse);
  });

  test(
    'canceling remote search does not cancel the directory request',
    () async {
      final listCompleter = Completer<CloudDrivePageResult>();
      final source = _FakeCloudDriveSource(
        supportsRemoteSearch: true,
        supportsPagination: true,
        pages: const {},
        totalCount: 1,
        listCompleter: listCompleter,
      );
      final container = ProviderContainer(
        overrides: [
          cloudDriveSourceProvider.overrideWith((ref, mode) => source),
        ],
      );
      addTearDown(container.dispose);
      const args = (mode: CloudDriveMode.alistApi, path: '/');
      final subscription = container.listen(
        cloudDriveBrowserControllerProvider(args),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final controller = container.read(
        cloudDriveBrowserControllerProvider(args).notifier,
      );

      final load = controller.loadInitial();
      await controller.search('result');
      controller.exitSearch();
      listCompleter.complete(
        CloudDrivePageResult(items: [_audio('/one.mp3')], totalCount: 1),
      );
      await load;

      final state = container.read(cloudDriveBrowserControllerProvider(args));
      expect(state.isSearchMode, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.nodes.single.path, '/one.mp3');
    },
  );

  test('loadIfNeeded reuses the loaded directory until refresh', () async {
    final source = _FakeCloudDriveSource(
      supportsRemoteSearch: false,
      supportsPagination: false,
      pages: {
        1: [_folder('/folder')],
      },
      totalCount: 1,
    );
    final container = ProviderContainer(
      overrides: [cloudDriveSourceProvider.overrideWith((ref, mode) => source)],
    );
    addTearDown(container.dispose);
    const args = (mode: CloudDriveMode.alistApi, path: '/');
    final controller = container.read(
      cloudDriveBrowserControllerProvider(args).notifier,
    );

    await controller.loadIfNeeded();
    await controller.loadIfNeeded();
    expect(source.listCallCount, 1);

    await controller.refresh();
    expect(source.listCallCount, 2);
  });
}

FileNode _folder(String path) => FileNode(
  type: NodeType.folder,
  title: NodeFolder(path).name,
  path: path,
  remoteId: path,
  source: NodeSource.cloudDrive,
);

FileNode _audio(String path, {int size = 0}) => FileNode(
  type: NodeType.audio,
  title: NodeFolder(path).name,
  path: path,
  remoteId: path,
  size: size,
  source: NodeSource.cloudDrive,
);

class _FakeCloudDriveSource implements CloudDriveSource {
  _FakeCloudDriveSource({
    required this.supportsRemoteSearch,
    required this.supportsPagination,
    required this.pages,
    required this.totalCount,
    this.searchItems = const [],
    this.listCompleter,
  });

  @override
  final bool supportsRemoteSearch;

  @override
  final bool supportsPagination;

  final Map<int, List<FileNode>> pages;
  final int totalCount;
  final List<FileNode> searchItems;
  final Completer<CloudDrivePageResult>? listCompleter;
  int listCallCount = 0;
  int searchCallCount = 0;
  String? lastSearchPath;

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  NodeSource get nodeSource => NodeSource.cloudDrive;

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    listCallCount++;
    final pending = listCompleter;
    if (pending != null) return pending.future;
    return CloudDrivePageResult(
      items: pages[page] ?? const [],
      totalCount: totalCount,
    );
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async {
    searchCallCount++;
    lastSearchPath = path;
    return CloudDrivePageResult(
      items: searchItems,
      totalCount: searchItems.length,
    );
  }

  @override
  String describeError(Object error) => error.toString();
}
