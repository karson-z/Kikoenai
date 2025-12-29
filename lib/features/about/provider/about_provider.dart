import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log/kikoenai_log.dart';
import '../../../core/utils/version/auto_update.dart';
import '../../../core/widgets/layout/app_toast.dart';


/// 定义 Provider
final appUpdateProvider = AsyncNotifierProvider.autoDispose<AppUpdateNotifier, void>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // 初始化时不执行任何操作，等待调用
    return null;
  }

  /// 检查更新
  /// [isManual]: 是否为手动检查 (手动检查会显示 Toast 提示，自动检查则静默失败)
  Future<void> checkUpdate({bool isManual = false}) async {
    // 1. 设置为加载状态 (界面可以据此显示转圈圈)
    state = const AsyncValue.loading();

    // 2. 执行更新逻辑
    // 使用 AsyncValue.guard 可以自动捕获异常并转为 AsyncError 状态
    state = await AsyncValue.guard(() async {
      final autoUpdater = AutoUpdater();

      if (isManual) {
        await autoUpdater.manualCheckForUpdates();
      } else {
        await autoUpdater.autoCheckForUpdates();
      }
    });

    // 3. 处理错误 (如果有)
    if (state.hasError) {
      final error = state.error;
      final stack = state.stackTrace;

      // 记录日志
      KikoenaiLogger().e('Update: check update failed', error: error, stackTrace: stack);

      // 如果是手动检查，需要给用户反馈
      if (isManual) {
        KikoenaiToast.error('检查更新失败，请稍后重试');
      }
    }
  }
}