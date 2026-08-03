import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/config/app_version_config.dart';
import 'package:kikoenai/core/routes/app_router.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/theme/app_theme.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_provider.dart';
import '../core/theme/theme_view_model.dart';
import '../features/settings/provider/setting_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当用户开启桌面字幕的时候再挂起监听
    AppStorage.settingsBox.get(
          StorageKeys.desktopLyricsEnabled,
          defaultValue: false,
        )
        ? ref.listen(lyricsControllerProvider, (_, __) {})
        : null;
    final themeState = ref.watch(themeNotifierProvider);
    final router = ref.watch(goRouterProvider);
    final notifier = ref.read(defaultMarkTargetPlaylistProvider.notifier);
    if (ref.read(defaultMarkTargetPlaylistProvider) == null) {
      notifier.fetchAndCacheDefault();
    }

    return MaterialApp.router(
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      title: VersionConfig.appName,
      theme: AppTheme.light(
        themeState.seedColor,
        fontPreset: themeState.fontPreset,
      ),
      darkTheme: AppTheme.dark(
        themeState.seedColor,
        fontPreset: themeState.fontPreset,
      ),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}
