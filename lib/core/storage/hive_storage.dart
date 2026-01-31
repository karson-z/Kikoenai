import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/features/user/data/models/user.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kikoenai/features/auth/data/model/auth_response.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/widgets/player/state/player_state.dart';

import '../adapter/file_node_adapter.dart';
import '../adapter/history_adapter.dart';
import '../adapter/media_item_adapter.dart';
import '../adapter/player_state_adapter.dart';
import '../adapter/progressbar_state_adapter.dart';
import '../adapter/work_adapter.dart';
import '../adapter/work_info_adapter.dart';
class AppStorage {
  // 1. 定义强类型的 Box
  static late Box<AuthResponse> authBox;       // 登录信息
  static late Box<HistoryEntry> historyBox;    // 播放历史 (Key: WorkId)
  static late Box<AppPlayerState> playerBox;   // 播放器状态
  static late Box<dynamic> settingsBox;        // 通用设置/缓存 (String, Bool, List<String>)
  static late Box<dynamic> scannerBox;         // 扫描结果 (由于结构复杂，可用 dynamic 或专门的 Model)

  static late final String _hiveRootPath;
  /// 初始化 Hive 和所有 Box
  static Future<void> init() async {
    final appDocDir = await getApplicationSupportDirectory();
    _hiveRootPath = '${appDocDir.path}/hive_storage';

    // 初始化
    await Hive.initFlutter(_hiveRootPath);
    Hive.registerAdapter(AuthResponseAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ProgressBarStateAdapter());
    Hive.registerAdapter(MediaItemAdapter());
    Hive.registerAdapter(WorkInfoAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    Hive.registerAdapter(PlayerStateAdapter());
    Hive.registerAdapter(WorkAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());
    // 3. 并行打开 Box
    await Future.wait([
      _openBox<AuthResponse>(BoxNames.auth).then((val) => authBox = val),
      _openBox<HistoryEntry>(BoxNames.history).then((val) => historyBox = val),
      _openBox<AppPlayerState>(BoxNames.playerState).then((val) => playerBox = val),
      _openBox<dynamic>(BoxNames.settings).then((val) => settingsBox = val),
      _openBox<dynamic>(BoxNames.scanner).then((val) => scannerBox = val),
    ]);
  }

  /// 辅助方法：安全打开 Box
  static Future<Box<T>> _openBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint("Box $name 损坏，正在重建...");
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  // ==================== 备份与恢复功能 ====================

  static Future<void> backupBox(String boxName, String destPath) async {
    final boxFile = File('$_hiveRootPath/$boxName.hive');
    if (await boxFile.exists()) {
      await boxFile.copy(destPath);
    }
  }

  /// 智能合并历史记录 (Patch Logic)
  static Future<void> patchHistory(String backupPath) async {
    final file = File(backupPath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    // 打开临时 Box
    final tempBox = await Hive.openBox<HistoryEntry>(
        'temp_history_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes
    );

    // 遍历合并
    for (var entry in tempBox.toMap().entries) {
      final key = entry.key;
      final backupItem = entry.value;
      final localItem = historyBox.get(key);

      // 如果本地没有，或者备份比本地新，则写入
      if (localItem == null || backupItem.updatedAt > localItem.updatedAt) {
        await historyBox.put(key, backupItem);
      }
    }
    await tempBox.close();
  }

  /// 获取 Box 文件大小
  static Future<int> getBoxSize(String boxName) async {
    final file = File('$_hiveRootPath/$boxName.hive');
    if (await file.exists()) return await file.length();
    return 0;
  }

  /// 清理 Box
  static Future<void> clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }
}