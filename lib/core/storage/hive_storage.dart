import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/user/data/models/user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kikoenai/features/auth/data/model/auth_response.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import '../../features/player/data/model/player_state.dart';
import '../adapter/audio_service_repeat_mode_adapter.dart';
import '../adapter/history_adapter.dart';
import '../adapter/media_item_adapter.dart';
import '../adapter/progressbar_state_adapter.dart';
import '../adapter/work_adapter.dart';
import '../adapter/work_info_adapter.dart';
import '../enums/node_type.dart';
import '../model/lyric_model.dart';


class AppStorage {
  // 1. 定义强类型的 Box
  static late Box<AuthResponse> authBox;       // 登录信息
  static late Box<HistoryEntry> historyBox;    // 播放历史 (Key: WorkId)
  static late Box<AppPlayerState> playerBox;   // 播放器状态
  static late Box<dynamic> settingsBox;        // 通用设置/缓存
  static late Box<FileNode> scannerBox;        // 扫描结果
  static late Box<Work> scraperWorkBox;        // 爬取作品元数据

  static late final String _hiveRootPath;
  /// 初始化 Hive 和所有 Box
  static Future<void> init() async {
    final appDocDir = await getApplicationSupportDirectory();
    _hiveRootPath = '${appDocDir.path}/hive_storage';

    // 初始化
    await Hive.initFlutter(_hiveRootPath);

    Hive.registerAdapter(ProgressBarStateAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(LyricConfigModelAdapter());
    Hive.registerAdapter(AuthResponseAdapter());
    Hive.registerAdapter(MediaItemAdapter());
    Hive.registerAdapter(WorkInfoAdapter());
    Hive.registerAdapter(NodeTypeAdapter());
    Hive.registerAdapter(NodeStatusAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    Hive.registerAdapter(AudioServiceRepeatModeAdapter());
    Hive.registerAdapter(AppPlayerStateAdapter());
    Hive.registerAdapter(WorkAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());
    // 3. 并行打开 Box
    await Future.wait([
      _openBox<AuthResponse>(BoxNames.auth).then((val) => authBox = val),
      _openBox<HistoryEntry>(BoxNames.history).then((val) => historyBox = val),
      _openBox<AppPlayerState>(BoxNames.playerState).then((val) => playerBox = val),
      _openBox<dynamic>(BoxNames.settings).then((val) => settingsBox = val),
      _openBox<FileNode>(BoxNames.scanner).then((val) => scannerBox = val),
      _openBox<Work>(BoxNames.scraper).then((val) => scraperWorkBox = val),
    ]);
  }

  /// 辅助方法：安全打开 Box
  static Future<Box<T>> _openBox<T>(String name) async {
    try {
      // 防御性编程：如果已经打开，直接返回
      if (Hive.isBoxOpen(name)) {
        return Hive.box<T>(name);
      }
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint("Box $name 损坏或模型不匹配，正在重建... \n原因: $e");

      // 1. 尝试强行关闭处于“半打开”状态的 Box，释放文件句柄
      if (Hive.isBoxOpen(name)) {
        try {
          await Hive.box(name).close();
        } catch (_) {
          // 忽略关闭时的错误
        }
      }
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. 再次尝试从磁盘删除
      try {
        await Hive.deleteBoxFromDisk(name);
        debugPrint("Box $name 旧文件清理成功。");
      } catch (deleteError) {
        debugPrint("Box清理失败，请手动前往提示的 C 盘路径删除文件。错误: $deleteError");
      }

      // 4. 重新创建全新的 Box
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