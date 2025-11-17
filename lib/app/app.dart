import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/routes/app_router.dart';
import 'package:name_app/core/theme/app_theme.dart';
import 'package:name_app/core/constants/app_constants.dart';

import '../core/theme/theme_view_model.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // themeState 是一个 AsyncValue<ThemeState>
    final themeState = ref.watch(themeNotifierProvider);
    // router 保持不变
    final router = ref.watch(goRouterProvider);

    // 使用 .when() 来安全地处理所有状态
    return themeState.when(

      // 1. 数据加载成功
      data: (state) {
        // 在这个回调中，'state' 的类型是 ThemeState (已安全解包)
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          // 现在可以安全地访问 state.seedColor 和 state.mode
          theme: AppTheme.light(state.seedColor),
          darkTheme: AppTheme.dark(state.seedColor),
          themeMode: state.mode,
          routerConfig: router,
        );
      },

      // 2. 数据正在加载中
      loading: () {
        // 在主题加载期间显示一个加载指示器
        // 返回一个 MaterialApp 来保证在切换时 navigator 不出问题
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },

      // 3. 加载出错
      error: (err, stack) {
        // 显示一个错误界面
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Failed to load theme: $err'),
            ),
          ),
        );
      },
    );
  }
}