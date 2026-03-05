import 'package:hive_ce/hive.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import '../../storage/hive_storage.dart';


class ScraperStorage {
  /// 单例模式
  static final ScraperStorage _instance = ScraperStorage._internal();
  ScraperStorage._internal();
  factory ScraperStorage() => _instance;

  /// 获取 Hive Box 引用 (请替换为实际的存放路径)
  Box<Work> get _box => AppStorage.scraperWorkBox;

  /// 根据 RJ 码获取单个作品元数据
  Work? getWork(String rjCode) {
    if (rjCode.isEmpty) return null;
    return _box.get(rjCode.toUpperCase());
  }

  /// 获取所有已保存的作品元数据
  List<Work> getAllWorks() {
    return _box.values.toList();
  }

  /// 检查是否已存在该作品的元数据
  /// 场景：刮削器执行解析前，判断本地是否已有缓存，避免重复发起 API 请求
  bool hasWork(String rjCode) {
    if (rjCode.isEmpty) return false;
    return _box.containsKey(rjCode.toUpperCase());
  }

  /// 保存单个作品元数据
  /// 场景：解析器 (Parser) 成功拿到 API 数据后，将其落盘
  Future<void> saveWork(String rjCode, Work work) async {
    if (rjCode.isEmpty) return;
    await _box.put(rjCode.toUpperCase(), work);
  }

  /// 批量保存作品元数据
  /// 场景：批量导入元数据备份文件，或同时刮削多个作品时使用 putAll 提升性能
  Future<void> saveWorks(Map<String, Work> worksMap) async {
    if (worksMap.isEmpty) return;

    // 确保所有 Key 都符合大写规范
    final normalizedMap = worksMap.map(
            (key, value) => MapEntry(key.toUpperCase(), value)
    );
    await _box.putAll(normalizedMap);
  }

  /// 删除单个作品元数据
  /// 场景：用户手动解除本地文件夹与作品的关联，或清除指定错误数据
  Future<void> deleteWork(String rjCode) async {
    if (rjCode.isEmpty) return;
    await _box.delete(rjCode.toUpperCase());
  }

  /// 清空所有作品元数据 (慎用)
  /// 场景：恢复出厂设置或清空缓存
  Future<void> clearAll() async {
    await _box.clear();
  }
}