import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permission_service.dart'; // 引入上面写好的 service

/// 存储所有的权限状态映射
final permissionStatusProvider = AsyncNotifierProvider<PermissionStatusNotifier, Map<String, bool>>(() {
  return PermissionStatusNotifier();
});

class PermissionStatusNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    return await _fetchAllStatuses();
  }

  // 统一拉取所有权限状态
  Future<Map<String, bool>> _fetchAllStatuses() async {
    return {
      'storage': await PermissionService.checkStoragePermission(),
      'notification': await PermissionService.checkNotificationPermission(),
    };
  }

  // 暴露给 UI 的刷新方法 (从系统设置返回时调用)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAllStatuses());
  }

  // 点击“去设置”时的业务逻辑处理
  Future<void> handleRequest(String key) async {
    bool granted = false;

    // 1. 先尝试直接请求权限弹窗
    switch (key) {
      case 'storage': granted = await PermissionService.requestStoragePermission(); break;
      case 'notification': granted = await PermissionService.requestNotificationPermission(); break;
    }

    // 2. 如果用户之前点了“永久拒绝”，系统不会再弹窗，此时我们需要引导他去系统设置
    if (!granted) {
      await PermissionService.openSystemSettings();
    } else {
      // 如果直接授权成功，刷新局部状态
      refresh();
    }
  }
}