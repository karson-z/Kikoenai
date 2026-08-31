import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/features/cloud_drive/data/alist_api_cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import 'dl_media_models.dart';
import 'webdav_media_index.dart';

final dlMediaResolversProvider = Provider<List<DlMediaResolver>>((ref) {
  ref.watch(siteRegistryChangesProvider);
  final registry = ref.watch(siteRegistryProvider);
  final activeSiteId = ref.watch(activeSiteIdProvider);
  final webDavState = ref.watch(webDavConnectionControllerProvider);

  final resolvers = <DlMediaResolver>[
    LocalDlMediaResolver(FileScannerStorage()),
  ];

  final contentSites =
      registry.allRuntimes
          .where((runtime) => runtime.api.supports(SiteFeature.tracks))
          .toList(growable: false)
        ..sort((a, b) {
          if (a.siteId == activeSiteId && b.siteId != activeSiteId) return -1;
          if (b.siteId == activeSiteId && a.siteId != activeSiteId) return 1;
          return a.info.name.compareTo(b.info.name);
        });
  resolvers.addAll(contentSites.map(ContentSiteDlMediaResolver.new));

  final alistRuntime = registry.runtimeOf(AsmrGaySiteApi.info.id);
  if (alistRuntime?.api case final AlistSiteApi api) {
    final serverId = registry.currentServerOf(alistRuntime!.siteId)?.id;
    resolvers.add(
      AlistDlMediaResolver(
        source: AlistApiCloudDriveSource(api),
        instanceId: serverId,
      ),
    );
  }

  final webDavController = ref.read(
    webDavConnectionControllerProvider.notifier,
  );
  resolvers.add(
    WebDavDlMediaResolver(
      connection: webDavState,
      loadDirectory: webDavController.listDirectory,
    ),
  );
  return resolvers;
});

class LocalDlMediaResolver implements DlMediaResolver {
  LocalDlMediaResolver(this.storage);

  final FileScannerStorage storage;

  @override
  DlMediaSourceDescriptor get descriptor => const DlMediaSourceDescriptor(
    key: DlMediaSourceKey(
      kind: DlMediaSourceKind.local,
      providerId: 'local-media',
    ),
    label: '本地',
    nodeSource: NodeSource.localWork,
  );

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async {
    return storage.getWorkFileIndexLocally(workId);
  }
}

class ContentSiteDlMediaResolver implements DlMediaResolver {
  ContentSiteDlMediaResolver(this.runtime);

  final SiteRuntime runtime;

  @override
  DlMediaSourceDescriptor get descriptor => DlMediaSourceDescriptor(
    key: DlMediaSourceKey(
      kind: DlMediaSourceKind.contentSite,
      providerId: runtime.siteId,
    ),
    label: runtime.info.name,
    nodeSource: NodeSource.asmrServer,
  );

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async {
    final nodes = await runtime.api.getWorkTracks(workId.toString());
    if (nodes.isEmpty) return null;
    return FileNodeLibraryIndex.fromRemoteTree(
      roots: nodes,
      contentId: SiteContentId(
        siteId: runtime.siteId,
        remoteId: workId.toString(),
      ),
      source: NodeSource.asmrServer,
    );
  }
}

class AlistDlMediaResolver implements DlMediaResolver {
  AlistDlMediaResolver({required this.source, this.instanceId});

  final CloudDriveSource source;
  final String? instanceId;

  @override
  DlMediaSourceDescriptor get descriptor => DlMediaSourceDescriptor(
    key: DlMediaSourceKey(
      kind: DlMediaSourceKind.alist,
      providerId: source.id,
      instanceId: instanceId,
    ),
    label: source.label,
    nodeSource: source.nodeSource,
  );

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async {
    final candidates = <String>{};
    for (final query in {'RJ0$workId', 'RJ$workId'}) {
      var page = 1;
      while (true) {
        final result = await source.search(
          path: '/',
          query: query,
          scope: 0,
          page: page,
          pageSize: 100,
        );
        for (final node in result.items) {
          final identityText = '${node.title} ${node.path ?? ''}';
          if (!WebDavMediaIndexService.extractWorkIds(
            identityText,
          ).contains(workId)) {
            continue;
          }
          final path = node.isFolder
              ? node.path
              : node.folderPath ?? node.parentPath;
          if (path != null && path.isNotEmpty) {
            candidates.add(path);
          }
        }
        if (!source.supportsPagination || page * 100 >= result.totalCount) {
          break;
        }
        page++;
      }
    }
    if (candidates.isEmpty) return null;

    return _loadCandidateDirectories(
      sourceKey: descriptor.key,
      workId: workId,
      candidatePaths: _removeNestedCandidatePaths(candidates),
      nodeSource: source.nodeSource,
      siteId: source.id,
      loadDirectory: _loadDirectory,
    );
  }

  Future<List<FileNode>> _loadDirectory(String path) async {
    final nodes = <FileNode>[];
    var page = 1;
    while (true) {
      final result = await source.list(path: path, page: page, pageSize: 100);
      nodes.addAll(result.items);
      if (!source.supportsPagination || page * 100 >= result.totalCount) break;
      page++;
    }
    return nodes;
  }
}

class WebDavDlMediaResolver implements DlMediaResolver {
  WebDavDlMediaResolver({
    required this.connection,
    required this.loadDirectory,
  });

  final WebDavSessionState connection;
  final WebDavDirectoryLoader loadDirectory;

  String? get _fingerprint => connection.serverUrl.isEmpty
      ? null
      : WebDavMediaIndexService.fingerprintFor(
          serverUrl: connection.serverUrl,
          username: connection.username,
          rootPath: connection.rootPath,
        );

  @override
  DlMediaSourceDescriptor get descriptor => DlMediaSourceDescriptor(
    key: DlMediaSourceKey(
      kind: DlMediaSourceKind.webDav,
      providerId: webDavSiteId,
      instanceId: _fingerprint,
    ),
    label: 'WebDAV',
    nodeSource: NodeSource.cloudDrive,
  );

  @override
  Future<FileNodeLibraryIndex?> resolve(int workId) async {
    final fingerprint = _fingerprint;
    if (!connection.isConnected || fingerprint == null) {
      throw const DlMediaSourceUnavailable('尚未连接 WebDAV');
    }

    final service = WebDavMediaIndexService.instance;
    var snapshot = service.read(fingerprint);
    if (snapshot == null) {
      snapshot = await service.ensureFresh(
        fingerprint: fingerprint,
        rootPath: connection.rootPath,
        loadDirectory: loadDirectory,
      );
    } else if (!service.isFresh(snapshot)) {
      final refresh = service.ensureFresh(
        fingerprint: fingerprint,
        rootPath: connection.rootPath,
        loadDirectory: loadDirectory,
      );
      if (snapshot.pathsFor(workId).isEmpty) {
        snapshot = await refresh;
      } else {
        unawaited(refresh);
      }
    }
    final candidates = snapshot?.pathsFor(workId) ?? const [];
    if (candidates.isEmpty) return null;

    return _loadCandidateDirectories(
      sourceKey: descriptor.key,
      workId: workId,
      candidatePaths: candidates,
      nodeSource: NodeSource.cloudDrive,
      siteId: webDavSiteId,
      loadDirectory: loadDirectory,
    );
  }
}

Future<FileNodeLibraryIndex?> _loadCandidateDirectories({
  required DlMediaSourceKey sourceKey,
  required int workId,
  required Iterable<String> candidatePaths,
  required NodeSource nodeSource,
  required String siteId,
  required Future<List<FileNode>> Function(String path) loadDirectory,
}) async {
  final candidates = _removeNestedCandidatePaths(candidatePaths);
  if (candidates.isEmpty) return null;
  final rootPath =
      'dl-media://${Uri.encodeComponent(sourceKey.storageKey)}/$workId';
  final files = <FileNode>[];
  final usedLabels = <String, int>{};
  final showCopyFolder = candidates.length > 1;

  for (
    var candidateIndex = 0;
    candidateIndex < candidates.length;
    candidateIndex++
  ) {
    final candidate = FileNodeLibraryIndex.normalizePath(
      candidates[candidateIndex],
    );
    var label = FileNodeLibraryIndex.baseName(candidate);
    if (label.isEmpty) label = '副本 ${candidateIndex + 1}';
    final duplicateIndex = (usedLabels[label] ?? 0) + 1;
    usedLabels[label] = duplicateIndex;
    if (duplicateIndex > 1) label = '$label ($duplicateIndex)';

    final queue = ListQueue<String>()..add(candidate);
    final visited = <String>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!visited.add(current.toLowerCase())) continue;
      final nodes = await loadDirectory(current);
      for (final node in nodes) {
        final remotePath = FileNodeLibraryIndex.normalizePath(
          node.path ?? NodeFolder.joinPath(current, node.title),
        );
        if (node.isFolder) {
          queue.add(remotePath);
          continue;
        }

        var relative =
            remotePath.toLowerCase().startsWith(candidate.toLowerCase())
            ? remotePath.substring(candidate.length)
            : node.title;
        relative = relative.replaceFirst(RegExp(r'^/+'), '');
        final indexedParent = showCopyFolder
            ? NodeFolder.joinPath(rootPath, label)
            : rootPath;
        final indexedPath = NodeFolder.joinPath(indexedParent, relative);
        final indexedFolder = FileNodeLibraryIndex.dirName(indexedPath);
        files.add(
          node.copyWith(
            children: null,
            path: indexedPath,
            folderPath: indexedFolder,
            parentPath: indexedFolder,
            rootPath: rootPath,
            source: nodeSource,
            workId: workId,
            siteId: node.siteId ?? siteId,
            remoteId: node.remoteId ?? remotePath,
          ),
        );
      }
    }
  }
  if (files.isEmpty) return null;
  return FileNodeLibraryIndex(
    flatNodes: files,
    rootPath: rootPath,
    fallbackFolderSource: nodeSource,
  );
}

List<String> _removeNestedCandidatePaths(Iterable<String> values) {
  final sorted = values.map(FileNodeLibraryIndex.normalizePath).toSet().toList()
    ..sort((a, b) => a.length.compareTo(b.length));
  final result = <String>[];
  for (final candidate in sorted) {
    final lower = candidate.toLowerCase();
    if (result.any((path) {
      final parent = path.toLowerCase();
      return lower == parent || lower.startsWith('$parent/');
    })) {
      continue;
    }
    result.add(candidate);
  }
  return result;
}
