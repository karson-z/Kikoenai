class AppRoutes {
  // 一级根路由
  static const String home = '/';
  static const String user = '/user';
  static const String album = '/album';
  static const String category = '/category';
  static const String search = '/search';
  static const String login = '/login';
  static const String localMedia = '/media';
  static const String cloudDrive = '/webdav';

  @Deprecated('Use cloudDrive instead.')
  static const String webDav = cloudDrive;
  static const String parsedWorks = '/parsed';
  static const String test = '/test';
  static const String siteUnavailable = '/site-unavailable';

  // 基础路径
  static const String settings = '/settings';
  static const String detail = '/detail';
  static const String imageView = '/image_preview';
  static const String hotAndRecommend = '/hot_and_recommend';
  // ==============================
  // 二级目录：通过拼接实现
  // ==============================

  // 关于页面
  static String get about => '$settings/about';
  // 设置子项
  static String get settingsTheme => '$settings/theme';
  static String get settingsPermission => '$settings/permission';
  static String get settingsCache => '$settings/cache';
  static String get settingsAccount => '$settings/account';
  static String get settingsComment => '$settings/comment';
  static String get settingsLog => '$settings/log';
  static String get settingsGlobalFilter => '$settings/filter';

  static List<String> get mainPages => [
    AppRoutes.home,
    AppRoutes.category,
    AppRoutes.localMedia,
    AppRoutes.cloudDrive,
    AppRoutes.parsedWorks,
    AppRoutes.user,
    AppRoutes.test,
  ];
  static String toRelative(String path) {
    // 比如把 '/settings/permission' 变成 'permission'
    return path.split('/').last;
  }
}
