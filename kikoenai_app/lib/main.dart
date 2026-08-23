import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/service/download/download_service.dart';
import 'package:kikoenai/core/service/site/site_api_setup.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';
import 'package:kikoenai/core/utils/window/window_init_desktop.dart';
import 'package:kikoenai/core/theme/app_theme.dart';
import 'package:media_kit/media_kit.dart';
import 'app/app.dart';
import 'core/service/audio/audio_service.dart';
import 'core/service/proxy/auto_proxy_service.dart';
import 'core/service/file/local_media_sync_scheduler.dart';
import 'core/service/player/player_service.dart';
import 'core/storage/hive_key.dart';
import 'core/storage/hive_storage.dart';
import 'core/utils/version/auto_update.dart';
import 'features/overly-lyrics/page/overly_lyrics_panel.dart';
import 'features/overly-lyrics/provider/overly_lyrics_manager.dart';
import 'features/overly-lyrics/provider/overly_lyrics_provider.dart';

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  runApp(
    ProviderScope(
      overrides: [
        subtitleEndpointProvider.overrideWithValue(SubtitleEndpoint.overlay),
      ],
      child: const _OverlayApp(),
    ),
  );
}

class _OverlayApp extends ConsumerWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const seedColor = Color(0xFF4CAF50);
    return ValueListenableBuilder(
      valueListenable: AppStorage.settingsBox.listenable(
        keys: [StorageKeys.themeFontPreset],
      ),
      builder: (context, box, child) {
        final fontPresetKey = box.get(StorageKeys.themeFontPreset) as String?;
        final fontPreset = AppFontPreset.fromStorageKey(fontPresetKey);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            seedColor,
            fontPreset: fontPreset,
          ).copyWith(scaffoldBackgroundColor: Colors.transparent),
          darkTheme: AppTheme.dark(
            seedColor,
            fontPreset: fontPreset,
          ).copyWith(scaffoldBackgroundColor: Colors.transparent),
          home: child,
        );
      },
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: LyricsOverlayContent(),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // 在主 isolate 提前创建全局唯一的 Player，明确其归属（media_kit 的 Player
  // 会 spawn 专属 isolate + 原生 mpv）。若等音频服务/UI 再创建，一旦未来
  // audio handler 被移到其他 isolate，会静默产生第二个 Player 导致
  // 热重载/热重启崩溃。
  PlayerService.instance;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 强制透明
      statusBarIconBrightness: Brightness.dark, // 设置图标颜色：dark 为黑色图标，light 为白色图标
    ),
  );
  await AppStorage.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AudioServiceSingleton.init();
  await ProxyService.init();
  await DownloadService.init();
  debugPrint('开始初始化站点 API...');
  // api 服务器选择以及初始化不再阻塞
  unawaited(setupSiteApi());
  setupDesktopWindow();
  unawaited(LocalMediaSyncScheduler.instance.runStartupCheck());
  // 启动后延迟自动检查更新（由设置项“自动更新”控制；发现新版本会弹窗提示）
  unawaited(
    Future.delayed(
      const Duration(seconds: 3),
      () => AutoUpdater().autoCheckForUpdates(),
    ),
  );
  //  Failed to update ui::AXTree, error: 342 will not be in the tree and is not the new root
  // ExcludeSemantics 会禁用整个 app 的无障碍功能，避免这个bug
  runApp(const ProviderScope(child: ExcludeSemantics(child: MyApp())));
}
