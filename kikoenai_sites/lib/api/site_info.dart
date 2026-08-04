import 'server_info.dart';

/// 描述一个站点的基本信息。
class SiteInfo {
  /// 站点唯一标识（如 `asmr.one`、`dlsite`）
  final String id;

  /// 站点显示名称
  final String name;

  /// 站点版本
  final String version;

  /// 站点可用的服务器列表。
  ///
  /// 同一站点的不同镜像 / CDN 节点。运行时可通过 [id] 切换，
  /// 应用启动时可自动选择健康的服务器。
  ///
  /// 默认空列表（单服务器站点可省略）。
  final List<ServerInfo> servers;

  const SiteInfo({
    required this.id,
    required this.name,
    required this.version,
    this.servers = const [],
  });

  /// 默认服务器（[servers] 中第一个 `isDefault=true` 的，否则取首个，再否则 null）
  ServerInfo? get defaultServer {
    if (servers.isEmpty) return null;
    return servers.firstWhere((s) => s.isDefault, orElse: () => servers.first);
  }

  /// Creates runtime metadata while preserving the plugin's static identity.
  ///
  /// This is primarily used by self-hosted sites whose server list is supplied
  /// by the host application instead of being compiled into the plugin.
  SiteInfo copyWith({
    String? id,
    String? name,
    String? version,
    List<ServerInfo>? servers,
  }) => SiteInfo(
    id: id ?? this.id,
    name: name ?? this.name,
    version: version ?? this.version,
    servers: servers ?? this.servers,
  );

  @override
  String toString() =>
      'SiteInfo($id, $name, v$version, servers: ${servers.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
