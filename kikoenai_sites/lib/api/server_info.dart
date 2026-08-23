import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'server_info.g.dart';

/// 站点服务器信息。
///
/// 描述同一站点的不同镜像 / CDN 节点。同一站点可注册多个 [ServerInfo]，
/// 运行时通过 [id] 标识进行切换，应用启动时可自动选择健康的服务器。
@HiveType(typeId: TypeIds.serverInfo, adapterName: 'ServerInfoAdapter')
class ServerInfo {
  /// 服务器唯一标识（站点内唯一），如 `'official'` / `'mirror-jp'`
  @HiveField(0)
  final String id;

  /// 完整 baseUrl，如 `'https://api.asmr-200.com/api'`
  ///
  /// 切换服务器时，HTTP 客户端会用此值更新自己的 baseUrl。
  @HiveField(1)
  final String baseUrl;

  /// 显示名称（用于 UI 列表展示），如 `'官方线路'` / `'日本镜像'`
  @HiveField(2)
  final String label;

  /// 区域 / 地理标签（可选），如 `'CN'` / `'JP'` / `'US'`
  @HiveField(3)
  final String? region;

  /// 是否默认服务器（站点启动时的首选）
  @HiveField(4)
  final bool isDefault;

  /// 可选的显式端口。设置后会覆盖 [baseUrl] 中已有的端口。
  @HiveField(5)
  final int? port;

  /// 是否允许该服务器使用应用检测到的系统代理。
  ///
  /// false 时对应的 HTTP client 会强制直连。
  @HiveField(6)
  final bool useProxy;

  const ServerInfo({
    required this.id,
    required this.baseUrl,
    required this.label,
    this.region,
    this.isDefault = false,
    this.port,
    this.useProxy = true,
  }) : assert(port == null || (port > 0 && port <= 65535));

  /// 合并显式端口后的实际请求地址。
  String get resolvedBaseUrl {
    final configuredPort = port;
    if (configuredPort == null) return baseUrl;
    if (configuredPort <= 0 || configuredPort > 65535) {
      throw RangeError.range(configuredPort, 1, 65535, 'port');
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('服务器 baseUrl 无效: $baseUrl');
    }
    return uri.replace(port: configuredPort).toString();
  }

  @override
  String toString() =>
      'ServerInfo($id, $label, $resolvedBaseUrl, useProxy: $useProxy)';

  @override
  bool operator ==(Object other) =>
      other is ServerInfo &&
      other.id == id &&
      other.baseUrl == baseUrl &&
      other.port == port &&
      other.useProxy == useProxy;

  @override
  int get hashCode => Object.hash(id, baseUrl, port, useProxy);
}
