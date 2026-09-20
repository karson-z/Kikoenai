import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_sites/api/server_info.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:path_provider/path_provider.dart';

class AppStorage {
  // 1. 定义强类型的 Box
  static late Box<AuthResponse> authBox; // 登录信息
  static late Box<HistoryEntry> historyBox; // 播放历史 (Key: session.id)
  static late Box<WorkProgressPoint> workProgressBox; // 作品断点进度 (Key: scopeKey)
  static late Box<dynamic> settingsBox; // 通用设置/缓存
  static late Box<FileNode> scannerBox; // 扫描结果
  static late Box<Work> scraperWorkBox; // 爬取作品元数据
  static late Box<FileNode>
  lyricMatchBox; // 字幕匹配缓存 (Key: audio.id, Value: FileNode)
  static late Box<SearchTag> filterTagsBox; // 全局筛选
  static late Box<ScanTarget> scanTargetBox; // 扫描目标

  static late final String _hiveRootPath;

  /// 初始化 Hive 和所有 Box
  static Future<void> init() async {
    final appDocDir = await getApplicationSupportDirectory();
    _hiveRootPath = '${appDocDir.path}/hive_storage';

    // 初始化
    await Hive.initFlutter(_hiveRootPath);

    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(LyricConfigModelAdapter());
    Hive.registerAdapter(AuthResponseAdapter());
    Hive.registerAdapter(WorkInfoAdapter());
    Hive.registerAdapter(NodeTypeAdapter());
    Hive.registerAdapter(NodeStatusAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    Hive.registerAdapter(PlaybackItemAdapter());
    Hive.registerAdapter(PlaybackSessionAdapter());
    Hive.registerAdapter(CircleAdapter());
    Hive.registerAdapter(RankAdapter());
    Hive.registerAdapter(TagAdapter());
    Hive.registerAdapter(VAAdapter());
    Hive.registerAdapter(RateCountDetailAdapter());
    Hive.registerAdapter(OtherLanguageEditionAdapter());
    Hive.registerAdapter(WorkAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());
    Hive.registerAdapter(WorkProgressPointAdapter());
    Hive.registerAdapter(NodeSourceAdapter());
    Hive.registerAdapter(SearchTagAdapter());
    Hive.registerAdapter(ScanModeAdapter());
    Hive.registerAdapter(ScanTargetAdapter());
    Hive.registerAdapter(ServerInfoAdapter());
    // 3. 并行打开 Box
    await Future.wait([
      _openBox<AuthResponse>(BoxNames.auth).then((val) => authBox = val),
      _openBox<HistoryEntry>(BoxNames.history).then((val) => historyBox = val),
      _openBox<WorkProgressPoint>(
        BoxNames.workProgress,
      ).then((val) => workProgressBox = val),
      _openBox<dynamic>(BoxNames.settings).then((val) => settingsBox = val),
      _openBox<FileNode>(BoxNames.scanner).then((val) => scannerBox = val),
      _openBox<Work>(BoxNames.scraper).then((val) => scraperWorkBox = val),
      _openBox<FileNode>(
        BoxNames.lyricsMatch,
      ).then((val) => lyricMatchBox = val),
      _openBox<SearchTag>(
        BoxNames.globalFilterTags,
      ).then((val) => filterTagsBox = val),
      _openBox<ScanTarget>(
        BoxNames.scanTarget,
      ).then((val) => scanTargetBox = val),
    ]);

    // 清理历史遗留：设置页已移除的"背景处理与性能"项
    // （模糊半径/缩放分辨率/编码质量），删除旧版存过的残留值。
    await Future.wait([
      settingsBox.delete('blur_background'),
      settingsBox.delete('background_scale'),
      settingsBox.delete('background_quality'),
    ]);

    // 清理历史遗留：播放器状态 Box 已移除（冷启动恢复改由播放历史承担），
    // 删除旧版残留的 player_state 数据文件。
    await Hive.deleteBoxFromDisk('player_state');

    // 一次性迁移：历史记录从"按作品作用域"改写为"按播放会话"，
    // 并推导出作品断点进度索引。
    await _migrateHistoryToSessions();
  }

  /// 把旧版按 primaryKey 存储的历史改写为按 session.id 存储。
  ///
  /// 迁移前先在 Hive 目录内落一份文件备份（history.hive.pre_session.bak），
  /// 成功写入后打 [StorageKeys.historySessionMigrated] 标记；失败不打标记，
  /// 下次启动自动重试（重复执行按 session.id 去重，天然幂等）。
  static Future<void> _migrateHistoryToSessions() async {
    if (settingsBox.get(StorageKeys.historySessionMigrated) == true) return;

    try {
      // 迁移前备份，仅保留最近一份。
      final boxFile = File('$_hiveRootPath/${BoxNames.history}.hive');
      if (await boxFile.exists()) {
        final backup = File('$boxFile.pre_session.bak');
        await boxFile.copy(backup.path);
      }

      final result = HistoryMigration.buildSessionMaps(
        historyBox.values.toList(),
      );

      await historyBox.clear();
      await historyBox.putAll(result.sessions);
      await workProgressBox.putAll(result.progress);
      await settingsBox.put(StorageKeys.historySessionMigrated, true);
    } catch (e) {
      debugPrint('历史记录会话化迁移失败，将在下次启动重试: $e');
    }
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
  // static Future<void> patchHistory(String backupPath) async {
  //   final file = File(backupPath);
  //   if (!await file.exists()) return;
  //
  //   final bytes = await file.readAsBytes();
  //   // 打开临时 Box
  //   final tempBox = await Hive.openBox<HistoryEntry>(
  //       'temp_history_${DateTime.now().millisecondsSinceEpoch}',
  //       bytes: bytes
  //   );
  //
  //   // 遍历合并
  //   for (var entry in tempBox.toMap().entries) {
  //     final key = entry.key;
  //     final backupItem = entry.value;
  //     final localItem = historyBox.get(key);
  //
  //     // 如果本地没有，或者备份比本地新，则写入
  //     if (localItem == null || backupItem.updatedAt > localItem.updatedAt) {
  //       await historyBox.put(key, backupItem);
  //     }
  //   }
  //   await tempBox.close();
  // }

  /// 获取 Box 文件大小
  static Future<int> getBoxSize(String boxName) async {
    final file = File('$_hiveRootPath/$boxName.hive');
    if (await file.exists()) return await file.length();
    return 0;
  }

  /// 清理 Box
  static Future<void> clearBox(String boxName) async {
    // 核心修复：通过匹配 boxName，直接使用顶部已定义好的强类型实例进行清理，避免泛型丢失导致的异常
    switch (boxName) {
      case BoxNames.auth:
        await authBox.clear();
        break;
      case BoxNames.history:
        await historyBox.clear();
        break;
      case BoxNames.workProgress:
        await workProgressBox.clear();
        break;
      case BoxNames.settings:
        await settingsBox.clear();
        break;
      case BoxNames.scanner:
        await scannerBox.clear();
        break;
      case BoxNames.scraper:
        await scraperWorkBox.clear();
        break;
      default:
        // 兜底逻辑：处理那些没有定义为静态变量、或者确实是 dynamic 类型的临时 Box
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).clear();
        }
    }
  }
}
