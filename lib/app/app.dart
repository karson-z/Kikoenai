import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/config/app_version_config.dart';
import 'package:kikoenai/core/routes/app_router.dart';
import 'package:kikoenai/core/theme/app_theme.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';

import '../core/theme/theme_view_model.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // themeState 是一个 AsyncValue<ThemeState>
    final themeState = ref.watch(themeNotifierProvider);
    // router 保持不变
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      title: VersionConfig.appName,
      // 现在可以安全地访问 state.seedColor 和 state.mode
      theme: AppTheme.light(themeState.seedColor),
      darkTheme: AppTheme.dark(themeState.seedColor),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}