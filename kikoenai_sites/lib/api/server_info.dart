/// 站点服务器信息。
///
/// 描述同一站点的不同镜像 / CDN 节点。同一站点可注册多个 [ServerInfo]，
/// 运行时通过 [id] 标识进行切换，应用启动时可自动选择健康的服务器。
class ServerInfo {
  /// 服务器唯一标识（站点内唯一），如 `'official'` / `'mirror-jp'`
  final String id;

  /// 完整 baseUrl，如 `'https://api.asmr-200.com/api'`
  ///
  /// 切换服务器时，HTTP 客户端会用此值更新自己的 baseUrl。
  final String baseUrl;

  /// 显示名称（用于 UI 列表展示），如 `'官方线路'` / `'日本镜像'`
  final String label;

  /// 区域 / 地理标签（可选），如 `'CN'` / `'JP'` / `'US'`
  final String? region;

  /// 是否默认服务器（站点启动时的首选）
  final bool isDefault;

  const ServerInfo({
    required this.id,
    required this.baseUrl,
    required this.label,
    this.region,
    this.isDefault = false,
  });

  @override
  String toString() => 'ServerInfo($id, $label, $baseUrl)';

  @override
  bool operator ==(Object other) =>
      other is ServerInfo && other.id == id && other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(id, baseUrl);
}
