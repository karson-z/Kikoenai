import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/features/cloud_drive/data/alist_api_cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/data/webdav_cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

typedef PlayerCloudFileSourceRequest = ({
  PlaybackItem track,
  String? legacyConnectionId,
});

bool usesCloudFileBrowser(PlaybackItem track) =>
    track.fileOrigin != null ||
    track.source == NodeSource.asmrGay ||
    track.source == NodeSource.cloudDrive;

class PlayerCloudSourceException implements Exception {
  const PlayerCloudSourceException(this.message, {this.canBindLegacy = false});

  final String message;
  final bool canBindLegacy;

  @override
  String toString() => message;
}

/// 每个弹层解析独立来源；不会切换网盘主页选中的服务器。
final playerCloudFileSourceProvider = FutureProvider.autoDispose
    .family<BoundPlayerCloudSource, PlayerCloudFileSourceRequest>((
      ref,
      args,
    ) async {
      final track = args.track;
      final savedOrigin = track.fileOrigin;
      final isWebDav =
          savedOrigin?.kind == FileOriginKind.webDav ||
          (savedOrigin == null && track.siteId == webDavSiteId);

      if (isWebDav) {
        final connection = ref.watch(webDavConnectionControllerProvider);
        final path = savedOrigin?.filePath ?? track.remoteId;
        if (path == null || !path.startsWith('/')) {
          throw const PlayerCloudSourceException('历史记录缺少文件路径，请从网盘页重新定位文件');
        }
        final origin =
            savedOrigin ??
            FileOrigin(
              kind: FileOriginKind.webDav,
              connectionId: connection.connectionId,
              filePath: path,
              rootPath: connection.rootPath,
            );
        if (origin.connectionId != connection.connectionId) {
          throw const PlayerCloudSourceException(
            '当前 WebDAV 与文件的原始连接不同，请重新连接原服务器、账号和起始目录',
          );
        }
        if (!origin.contains(path)) {
          throw const PlayerCloudSourceException('文件位于配置的起始目录之外，请从网盘页重新定位文件');
        }
        if (savedOrigin == null) {
          final baseUri = Uri.tryParse(connection.serverUrl);
          final expected = baseUri == null
              ? null
              : WebDavController.buildFileUri(baseUri, path);
          final actual = Uri.tryParse(track.url);
          if (expected == null ||
              actual == null ||
              !_sameFileUri(expected, actual)) {
            throw const PlayerCloudSourceException(
              '旧记录无法核验原始 WebDAV 连接，请从网盘页重新定位文件',
            );
          }
          if (args.legacyConnectionId != connection.connectionId) {
            throw PlayerCloudSourceException(
              '旧记录未保存账号身份。确认使用当前 WebDAV 连接打开？\n'
              '${connection.serverUrl}\n账号：${connection.username.isEmpty ? '匿名' : connection.username}',
              canBindLegacy: true,
            );
          }
        }
        final controller = ref.read(
          webDavConnectionControllerProvider.notifier,
        );
        if (!connection.isConnected) {
          await controller.restoreSavedConnection();
        }
        void validate() {
          if (!ref.mounted) throw const PlayerCloudSourceException('文件管理已关闭');
          final current = ref.read(webDavConnectionControllerProvider);
          if (!current.isConnected ||
              current.connectionId != origin.connectionId) {
            throw const PlayerCloudSourceException('原 WebDAV 连接不可用，请重新连接后重试');
          }
        }

        validate();
        return BoundPlayerCloudSource(
          delegate: WebDavCloudDriveSource(controller),
          origin: origin,
          label:
              'WebDAV · ${connection.username.isEmpty ? '匿名' : connection.username}',
          validate: validate,
        );
      }

      if (savedOrigin?.kind != FileOriginKind.alist &&
          track.source != NodeSource.asmrGay) {
        throw const PlayerCloudSourceException('无法识别此网盘来源，请从网盘页重新定位文件');
      }
      final siteId = track.siteId ?? AsmrGaySiteApi.info.id;
      final runtime = ref.watch(siteRuntimeByIdProvider(siteId));
      final api = runtime.api;
      if (api is! AsmrGaySiteApi) {
        throw const PlayerCloudSourceException('此来源尚未支持目录浏览');
      }
      final path = savedOrigin?.filePath ?? track.remoteId;
      if (path == null || !path.startsWith('/')) {
        throw const PlayerCloudSourceException('历史记录缺少文件路径，请从网盘页重新定位文件');
      }
      FileOrigin? origin = savedOrigin;
      if (origin == null) {
        for (final server in runtime.info.servers) {
          final base = AsmrGaySiteApi.normalizeBaseUrl(server);
          final actual = Uri.tryParse(track.url);
          final expected = WebDavController.buildFileUri(
            Uri.parse('$base/d/'),
            path,
          );
          if (actual != null && _sameFileUri(expected, actual)) {
            origin = FileOrigin(
              kind: FileOriginKind.alist,
              connectionId: AsmrGaySiteApi.connectionIdForServer(server),
              filePath: path,
            );
            break;
          }
        }
        // CDN 链接不提供连接身份，不能据此猜测自定义服务器。
        if (origin == null && api.rawBaseUrl != null) {
          final actual = Uri.tryParse(track.url);
          final expected = WebDavController.buildFileUri(
            Uri.parse(api.rawBaseUrl!),
            path,
          );
          final hasBuiltIn = runtime.info.servers.any(
            (server) =>
                AsmrGaySiteApi.connectionIdForServer(server) ==
                'alist:asmr.gay:built-in',
          );
          if (actual != null && _sameFileUri(expected, actual) && hasBuiltIn) {
            origin = FileOrigin(
              kind: FileOriginKind.alist,
              connectionId: 'alist:asmr.gay:built-in',
              filePath: path,
            );
          }
        }
        if (origin == null) {
          throw const PlayerCloudSourceException(
            '旧记录无法核验原始 AList 来源，请从网盘页重新定位文件',
          );
        }
      }
      final resolvedOrigin = origin;
      final matches = runtime.info.servers
          .where(
            (server) =>
                AsmrGaySiteApi.connectionIdForServer(server) ==
                resolvedOrigin.connectionId,
          )
          .toList();
      if (matches.isEmpty) {
        throw const PlayerCloudSourceException('原 AList 来源已移除，请在来源设置中恢复原域名');
      }
      if (!resolvedOrigin.contains(path)) {
        throw const PlayerCloudSourceException('文件位于浏览根目录之外');
      }
      final server = matches.firstWhere(
        (item) => item.id == api.currentServer.id,
        orElse: () => matches.first,
      );
      final baseUrl = AsmrGaySiteApi.normalizeBaseUrl(server);
      final client = SitesHttpClient(
        config: RequestConfig(
          baseUrl: baseUrl,
          referer: '$baseUrl/',
          enableCookie: true,
          useProxy: server.useProxy,
        ),
        cookieManager: api.httpClient.cookieManager,
      );
      // 固定端点，无全局 failover，避免私有盘请求跳到另一个同路径来源。
      final boundApi = AsmrGaySiteApi(
        servers: [server],
        initialServer: server,
        httpClient: client,
        rawBaseUrl: null,
      );
      ref.onDispose(client.close);
      void validate() {
        if (!ref.mounted) throw const PlayerCloudSourceException('文件管理已关闭');
        final configured = ref.read(siteInfoByIdProvider(siteId)).servers;
        if (!configured.any(
          (item) =>
              AsmrGaySiteApi.connectionIdForServer(item) ==
              resolvedOrigin.connectionId,
        )) {
          throw const PlayerCloudSourceException('原 AList 来源已移除，请恢复原域名后重试');
        }
      }

      return BoundPlayerCloudSource(
        delegate: AlistApiCloudDriveSource(boundApi),
        origin: resolvedOrigin,
        label: 'AList · ${server.label}',
        validate: validate,
      );
    }, retry: (retryCount, error) => null);

bool _sameFileUri(Uri left, Uri right) =>
    left.scheme == right.scheme &&
    left.host == right.host &&
    left.port == right.port &&
    left.path == right.path;

/// 连接与根目录双重约束，递归收集同样通过此适配器。
class BoundPlayerCloudSource implements CloudDriveSource {
  const BoundPlayerCloudSource({
    required this.delegate,
    required this.origin,
    required this.label,
    required this.validate,
  });

  final CloudDriveSource delegate;
  final FileOrigin origin;
  final void Function() validate;

  @override
  final String label;
  @override
  String get id => origin.connectionId;
  @override
  NodeSource get nodeSource => delegate.nodeSource;
  @override
  bool get supportsRemoteSearch => delegate.supportsRemoteSearch;
  @override
  bool get supportsPagination => delegate.supportsPagination;

  void _checkPath(String path) {
    validate();
    if (!origin.contains(path)) {
      throw const PlayerCloudSourceException('无法访问配置的起始目录之外的路径');
    }
  }

  CloudDrivePageResult _bind(CloudDrivePageResult result) {
    validate();
    return CloudDrivePageResult(
      items: result.items
          .where((node) {
            final path = node.path ?? node.remoteId;
            return path != null &&
                path.startsWith('/') &&
                origin.contains(path);
          })
          .map((node) {
            final path = node.path ?? node.remoteId!;
            return node.copyWith(fileOrigin: origin.atPath(path));
          })
          .toList(growable: false),
      totalCount: result.totalCount,
    );
  }

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    _checkPath(path);
    return _bind(
      await delegate.list(path: path, page: page, pageSize: pageSize),
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
    _checkPath(path);
    return _bind(
      await delegate.search(
        path: path,
        query: query,
        scope: scope,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  String describeError(Object error) => error is PlayerCloudSourceException
      ? error.message
      : delegate.describeError(error);
}
