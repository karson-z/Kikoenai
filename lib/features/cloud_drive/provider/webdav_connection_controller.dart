import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

const String webDavSiteId = 'webdav';

class WebDavConnectionConfig {
  const WebDavConnectionConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.rootPath,
  });

  final String serverUrl;
  final String username;
  final String password;
  final String rootPath;

  WebDavConnectionConfig validated() {
    final uri = Uri.tryParse(serverUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('请输入完整的 WebDAV 地址');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('WebDAV 地址仅支持 HTTP 或 HTTPS');
    }
    if (uri.userInfo.isNotEmpty) {
      throw const FormatException('请在账号和密码栏填写凭据');
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw const FormatException('WebDAV 地址不能包含查询参数或锚点');
    }

    final normalizedRoot = WebDavController.normalizeRemotePath(rootPath);
    if (normalizedRoot.split('/').contains('..')) {
      throw const FormatException('起始目录不能包含 ..');
    }

    return WebDavConnectionConfig(
      serverUrl: uri.replace(path: _withTrailingSlash(uri.path)).toString(),
      username: username.trim(),
      password: password,
      rootPath: normalizedRoot,
    );
  }

  static String _withTrailingSlash(String path) {
    if (path.isEmpty) return '/';
    return path.endsWith('/') ? path : '$path/';
  }
}

class WebDavSessionState {
  const WebDavSessionState({
    this.serverUrl = '',
    this.username = '',
    this.rootPath = '/',
    this.isConnecting = false,
    this.isConnected = false,
    this.errorMessage,
    this.revision = 0,
  });

  final String serverUrl;
  final String username;
  final String rootPath;
  final bool isConnecting;
  final bool isConnected;
  final String? errorMessage;
  final int revision;

  WebDavSessionState copyWith({
    String? serverUrl,
    String? username,
    String? rootPath,
    bool? isConnecting,
    bool? isConnected,
    String? errorMessage,
    bool clearError = false,
    int? revision,
  }) {
    return WebDavSessionState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      rootPath: rootPath ?? this.rootPath,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      revision: revision ?? this.revision,
    );
  }
}

class WebDavController extends Notifier<WebDavSessionState> {
  webdav.Client? _client;
  Uri? _baseUri;

  @override
  WebDavSessionState build() {
    ref.onDispose(() => _client?.c.close(force: true));
    final box = AppStorage.settingsBox;
    return WebDavSessionState(
      serverUrl:
          box.get(StorageKeys.webDavServerUrl, defaultValue: '') as String,
      username: box.get(StorageKeys.webDavUsername, defaultValue: '') as String,
      rootPath:
          box.get(StorageKeys.webDavRootPath, defaultValue: '/') as String,
    );
  }

  Future<bool> connect(WebDavConnectionConfig rawConfig) async {
    WebDavConnectionConfig config;
    try {
      config = rawConfig.validated();
    } on FormatException catch (error) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: error.message,
      );
      return false;
    }

    state = state.copyWith(
      serverUrl: config.serverUrl,
      username: config.username,
      rootPath: config.rootPath,
      isConnecting: true,
      isConnected: false,
      clearError: true,
    );

    final client =
        webdav.newClient(
            config.serverUrl,
            user: config.username,
            password: config.password,
          )
          ..setConnectTimeout(15000)
          ..setSendTimeout(15000)
          ..setReceiveTimeout(30000);

    try {
      await client.readDir(config.rootPath);
      _client?.c.close(force: true);
      _client = client;
      _baseUri = Uri.parse(config.serverUrl);
      await AppStorage.settingsBox.putAll({
        StorageKeys.webDavServerUrl: config.serverUrl,
        StorageKeys.webDavUsername: config.username,
        StorageKeys.webDavRootPath: config.rootPath,
      });
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        clearError: true,
        revision: state.revision + 1,
      );
      return true;
    } catch (error) {
      client.c.close(force: true);
      _client = null;
      _baseUri = null;
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: describeError(error),
      );
      return false;
    }
  }

  void disconnect() {
    _client?.c.close(force: true);
    _client = null;
    _baseUri = null;
    state = state.copyWith(
      isConnecting: false,
      isConnected: false,
      clearError: true,
      revision: state.revision + 1,
    );
  }

  Future<List<FileNode>> listDirectory(String path) async {
    final client = _client;
    final baseUri = _baseUri;
    if (client == null || baseUri == null || !state.isConnected) {
      throw StateError('WebDAV 尚未连接');
    }

    try {
      final normalizedPath = normalizeRemotePath(path);
      final files = await client.readDir(normalizedPath);
      return files
          .map((file) => _toFileNode(file, normalizedPath, baseUri))
          .toList(growable: false);
    } catch (error) {
      throw WebDavBrowseException(describeError(error), error);
    }
  }

  static String normalizeRemotePath(String input) {
    var value = input.trim().replaceAll('\\', '/');
    if (value.isEmpty) return '/';
    if (!value.startsWith('/')) value = '/$value';
    value = value.replaceAll(RegExp(r'/+'), '/');
    if (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static Uri buildFileUri(Uri baseUri, String remotePath) {
    final baseSegments = baseUri.pathSegments.where((part) => part.isNotEmpty);
    final remoteSegments = normalizeRemotePath(
      remotePath,
    ).split('/').where((part) => part.isNotEmpty);
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      pathSegments: [...baseSegments, ...remoteSegments],
    );
  }

  static String describeError(Object error) {
    final source = error is WebDavBrowseException ? error.source : error;
    if (source is DioException) {
      final statusCode = source.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return '认证失败，请检查账号和密码';
      }
      if (statusCode == 404) return 'WebDAV 地址或起始目录不存在';
      if (statusCode == 405) return '服务器未允许 WebDAV 目录请求';
      if (source.type == DioExceptionType.connectionTimeout ||
          source.type == DioExceptionType.receiveTimeout ||
          source.type == DioExceptionType.sendTimeout) {
        return '连接超时，请检查地址和网络';
      }
      if (source.type == DioExceptionType.connectionError) {
        return '无法连接 WebDAV 服务器';
      }
      if (statusCode != null) return 'WebDAV 服务器返回错误 ($statusCode)';
    }
    if (source is FormatException) return source.message;
    return 'WebDAV 请求失败，请检查服务器配置';
  }

  FileNode _toFileNode(webdav.File file, String parentPath, Uri baseUri) {
    final title = (file.name == null || file.name!.isEmpty)
        ? NodeFolder(file.path ?? parentPath).name
        : file.name!;
    final fullPath = normalizeRemotePath(
      file.path ?? NodeFolder.joinPath(parentPath, title),
    );
    final isFolder = file.isDir == true;
    final fileUrl = isFolder
        ? null
        : buildFileUri(baseUri, fullPath).toString();
    final eTag = file.eTag?.trim();

    return FileNode(
      type: _resolveNodeType(title, isFolder, file.mimeType),
      title: title,
      hash: eTag == null || eTag.isEmpty ? fullPath : eTag,
      mediaStreamUrl: fileUrl,
      mediaDownloadUrl: fileUrl,
      size: file.size,
      lastModified: file.mTime?.millisecondsSinceEpoch ?? 0,
      source: NodeSource.cloudDrive,
      path: fullPath,
      folderPath: parentPath,
      rootPath: state.rootPath,
      parentPath: parentPath,
      siteId: webDavSiteId,
      remoteId: fullPath,
    );
  }

  static NodeType _resolveNodeType(
    String name,
    bool isFolder,
    String? mimeType,
  ) {
    if (isFolder) return NodeType.folder;
    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('audio/') || FileExtensions.isAudio(name)) {
      return NodeType.audio;
    }
    if (mime.startsWith('video/') || FileExtensions.isVideo(name)) {
      return NodeType.video;
    }
    if (mime.startsWith('image/') || FileExtensions.isImage(name)) {
      return NodeType.image;
    }
    if (mime.startsWith('text/') ||
        FileExtensions.isDocument(name) ||
        FileExtensions.isSubtitle(name)) {
      return NodeType.text;
    }
    return NodeType.other;
  }
}

class WebDavBrowseException implements Exception {
  const WebDavBrowseException(this.message, this.source);

  final String message;
  final Object source;

  @override
  String toString() => message;
}

final webDavConnectionControllerProvider =
    NotifierProvider<WebDavController, WebDavSessionState>(
      WebDavController.new,
    );
