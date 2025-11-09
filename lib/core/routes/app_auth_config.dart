import 'package:name_app/core/routes/app_routes.dart';

/// 应用程序路由的认证配置表。
/// 默认所有路由都不需要认证 。
/// 此表中列出的路由若设置为 `false`，则表示不需要认证（豁免）。
///配置需要认证的路由即可
/// Key: 路由路径 (例如 AppRoutes.home)
/// Value: 是否需要认证 (true/false)
const Map<String, bool> routeAuthConfigs = {
  AppRoutes.user: true,
};
