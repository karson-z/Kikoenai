import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/routes/app_route_surface_policy.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/features/album/model/album_detail_args.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_aggregation_controller.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_models.dart';
import 'package:kikoenai/features/dl_page/media/dl_media_resolvers.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _MemoryPreferenceRepository implements DlMediaPreferenceRepository {
  final Map<int, String> values = {};

  @override
  String? read(int workId) => values[workId];

  @override
  Future<void> save(int workId, String sourceKey) async {
    values[workId] = sourceKey;
  }
}

class _FakeResolver implements DlMediaResolver {
  _FakeResolver({required this.descriptor, required this.callback});

  @override
  final DlMediaSourceDescriptor descriptor;
  final Future<FileNodeLibraryIndex?> Function(int workId) callback;
  int calls = 0;

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) {
    calls++;
    return callback(workId);
  }
}

class _FakeCloudDriveSource implements CloudDriveSource {
  final List<String> searchQueries = [];

  @override
  String get id => 'alist.test';

  @override
  String get label => 'AList Test';

  @override
  NodeSource get nodeSource => NodeSource.asmrGay;

  @override
  bool get supportsPagination => true;

  @override
  bool get supportsRemoteSearch => true;

  @override
  String describeError(Object error) => error.toString();

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async {
    searchQueries.add(query);
    if (page > 1) return const CloudDrivePageResult(items: [], totalCount: 3);
    return CloudDrivePageResult(
      totalCount: 3,
      items: [
        FileNode(
          type: NodeType.folder,
          title: 'RJ01234567 first',
          path: '/A/RJ01234567 first',
          source: nodeSource,
        ),
        FileNode(
          type: NodeType.folder,
          title: 'RJ1234567 second',
          path: '/B/RJ1234567 second',
          source: nodeSource,
        ),
        FileNode(
          type: NodeType.folder,
          title: 'XRJ01234567 ignored',
          path: '/C/XRJ01234567 ignored',
          source: nodeSource,
        ),
      ],
    );
  }

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    if (page > 1) return const CloudDrivePageResult(items: [], totalCount: 1);
    return CloudDrivePageResult(
      totalCount: 1,
      items: [
        FileNode(
          type: NodeType.audio,
          title: 'track.mp3',
          path: '$path/track.mp3',
          folderPath: path,
          mediaStreamUrl: 'https://example.test$path/track.mp3',
          source: nodeSource,
          siteId: id,
          remoteId: '$path/track.mp3',
        ),
      ],
    );
  }
}

DlMediaSourceDescriptor _descriptor(
  DlMediaSourceKind kind,
  String id,
  String label,
) {
  return DlMediaSourceDescriptor(
    key: DlMediaSourceKey(kind: kind, providerId: id),
    label: label,
    nodeSource: kind == DlMediaSourceKind.local
        ? NodeSource.localWork
        : NodeSource.asmrServer,
  );
}

FileNodeLibraryIndex _index(String root, NodeSource source) {
  return FileNodeLibraryIndex(
    flatNodes: [
      FileNode(
        type: NodeType.audio,
        title: 'track.mp3',
        path: '$root/track.mp3',
        folderPath: root,
        rootPath: root,
        mediaStreamUrl: '$root/track.mp3',
        source: source,
      ),
    ],
    rootPath: root,
    fallbackFolderSource: source,
  );
}

Future<DlMediaAggregationState> _waitForCompletion(
  ProviderContainer container,
  int workId,
) async {
  final provider = dlMediaAggregationProvider(workId);
  for (var attempt = 0; attempt < 100; attempt++) {
    await Future<void>.delayed(Duration.zero);
    final state = container.read(provider);
    if (!state.hasLoading && !state.isRefreshingAll) return state;
  }
  fail('DL media aggregation did not complete');
}

void main() {
  test(
    'DL detail route bypasses remote-site surface gating only in DL mode',
    () {
      expect(
        appRouteSurfacePolicy.surfaceFor(
          AppRoutes.detail,
          extra: const AlbumDetailArgs(mode: AlbumDetailMode.dlLibrary),
        ),
        isNull,
      );
      expect(
        appRouteSurfacePolicy.surfaceFor(
          AppRoutes.detail,
          extra: const AlbumDetailArgs(mode: AlbumDetailMode.remote),
        ),
        AppSurface.remoteAlbumDetailPage,
      );
    },
  );

  test('local media wins while source failures remain isolated', () async {
    const workId = 81234567;
    final local = _FakeResolver(
      descriptor: _descriptor(DlMediaSourceKind.local, 'local', '本地'),
      callback: (_) async => _index('/local', NodeSource.localWork),
    );
    final remote = _FakeResolver(
      descriptor: _descriptor(
        DlMediaSourceKind.contentSite,
        'remote',
        'Remote',
      ),
      callback: (_) async => _index('/remote', NodeSource.asmrServer),
    );
    final failed = _FakeResolver(
      descriptor: _descriptor(DlMediaSourceKind.alist, 'alist', 'AList'),
      callback: (_) async => throw StateError('offline'),
    );
    final preferences = _MemoryPreferenceRepository()
      ..values[workId] = remote.descriptor.key.storageKey;
    final container = ProviderContainer(
      overrides: [
        dlMediaResolversProvider.overrideWithValue([local, remote, failed]),
        dlMediaPreferenceRepositoryProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dlMediaAggregationProvider(workId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final state = await _waitForCompletion(container, workId);

    expect(state.visibleSources, hasLength(2));
    expect(state.selectedSource?.descriptor.key, local.descriptor.key);
    expect(
      state.sources
          .singleWhere(
            (source) => source.descriptor.key == failed.descriptor.key,
          )
          .status,
      DlMediaResolveStatus.error,
    );
  });

  test('remembered source is restored when no local media exists', () async {
    const workId = 81234568;
    final local = _FakeResolver(
      descriptor: _descriptor(DlMediaSourceKind.local, 'local', '本地'),
      callback: (_) async => null,
    );
    final first = _FakeResolver(
      descriptor: _descriptor(DlMediaSourceKind.contentSite, 'first', 'First'),
      callback: (_) async => _index('/first', NodeSource.asmrServer),
    );
    final preferred = _FakeResolver(
      descriptor: _descriptor(
        DlMediaSourceKind.contentSite,
        'preferred',
        'Preferred',
      ),
      callback: (_) async => _index('/preferred', NodeSource.asmrServer),
    );
    final preferences = _MemoryPreferenceRepository()
      ..values[workId] = preferred.descriptor.key.storageKey;
    final container = ProviderContainer(
      overrides: [
        dlMediaResolversProvider.overrideWithValue([local, first, preferred]),
        dlMediaPreferenceRepositoryProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dlMediaAggregationProvider(workId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final state = await _waitForCompletion(container, workId);

    expect(state.selectedSource?.descriptor.key, preferred.descriptor.key);
    await container
        .read(dlMediaAggregationProvider(workId).notifier)
        .selectSource(first.descriptor.key);
    expect(preferences.values[workId], first.descriptor.key.storageKey);
  });

  test('remote sources resolve while local lookup is still pending', () async {
    const workId = 81234570;
    final localResult = Completer<FileNodeLibraryIndex?>();
    final local = _FakeResolver(
      descriptor: _descriptor(DlMediaSourceKind.local, 'local', '本地'),
      callback: (_) => localResult.future,
    );
    final remote = _FakeResolver(
      descriptor: _descriptor(
        DlMediaSourceKind.contentSite,
        'remote',
        'Remote',
      ),
      callback: (_) async => _index('/remote', NodeSource.asmrServer),
    );
    final container = ProviderContainer(
      overrides: [
        dlMediaResolversProvider.overrideWithValue([local, remote]),
        dlMediaPreferenceRepositoryProvider.overrideWithValue(
          _MemoryPreferenceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dlMediaAggregationProvider(workId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    for (var attempt = 0; attempt < 100 && remote.calls == 0; attempt++) {
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(Duration.zero);

    final partial = container.read(dlMediaAggregationProvider(workId));
    expect(local.calls, 1);
    expect(remote.calls, 1);
    expect(partial.hasLoading, isTrue);
    expect(
      partial.visibleSources.map((source) => source.descriptor.key),
      contains(remote.descriptor.key),
    );

    localResult.complete(null);
    await _waitForCompletion(container, workId);
  });

  test('a stale request cannot replace a newer source refresh', () async {
    const workId = 81234569;
    final first = Completer<FileNodeLibraryIndex?>();
    final second = Completer<FileNodeLibraryIndex?>();
    var invocation = 0;
    final resolver = _FakeResolver(
      descriptor: _descriptor(
        DlMediaSourceKind.contentSite,
        'remote',
        'Remote',
      ),
      callback: (_) {
        invocation++;
        return invocation == 1 ? first.future : second.future;
      },
    );
    final container = ProviderContainer(
      overrides: [
        dlMediaResolversProvider.overrideWithValue([resolver]),
        dlMediaPreferenceRepositoryProvider.overrideWithValue(
          _MemoryPreferenceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dlMediaAggregationProvider(workId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    while (resolver.calls < 1) {
      await Future<void>.delayed(Duration.zero);
    }

    final refresh = container
        .read(dlMediaAggregationProvider(workId).notifier)
        .refreshSource(resolver.descriptor.key);
    while (resolver.calls < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    second.complete(_index('/new', NodeSource.asmrServer));
    await refresh;
    first.complete(_index('/old', NodeSource.asmrServer));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container
          .read(dlMediaAggregationProvider(workId))
          .selectedSource
          ?.index
          ?.rootPath,
      '/new',
    );
  });

  test(
    'AList keeps multiple matching copies as source-level folders',
    () async {
      final source = _FakeCloudDriveSource();
      final resolver = AlistDlMediaResolver(source: source);

      final index = await resolver.resolve(1234567);

      expect(source.searchQueries, containsAll({'RJ01234567', 'RJ1234567'}));
      expect(index, isNotNull);
      expect(index!.currentFolders, hasLength(2));
      expect(
        index.currentChildren
            .where((node) => node.isFolder)
            .map((node) => node.title),
        containsAll({'RJ01234567 first', 'RJ1234567 second'}),
      );
      expect(index.nodeByPath.values, everyElement(hasWorkId(1234567)));
    },
  );
}

Matcher hasWorkId(int workId) =>
    isA<FileNode>().having((node) => node.workId, 'workId', workId);
