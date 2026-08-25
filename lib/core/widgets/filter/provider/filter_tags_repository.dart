

import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/core/model/shared/search_tag.dart';

import '../../../storage/hive_storage.dart';

class FilterTagRepository {
  FilterTagRepository._();
  static final FilterTagRepository instance = FilterTagRepository._();

  Box<SearchTag> get _box => AppStorage.filterTagsBox;

  // 获取所有记录
  List<SearchTag> getAllTags() {
    return _box.values.toList();
  }

  // 根据类型获取记录
  List<SearchTag> getTagsByType(String type) {
    return _box.values.where((tag) => tag.type == type).toList();
  }

  // 插入或覆写记录
  Future<void> saveTag(SearchTag tag) async {
    final key = _findKey(tag.type, tag.name);
    if (key != null) {
      await _box.put(key, tag);
    } else {
      await _box.add(tag);
    }
  }

  // 批量存入记录
  Future<void> saveAllTags(List<SearchTag> tags) async {
    for (final tag in tags) {
      await saveTag(tag);
    }
  }

  // 状态反转 (切换 isExclude 的 true/false)
  Future<void> toggleTagStatus(SearchTag tag) async {
    final key = _findKey(tag.type, tag.name);
    if (key != null) {
      final toggledTag = SearchTag(tag.type, tag.name, !tag.isExclude);
      await _box.put(key, toggledTag);
    }
  }

  // 移除单条记录
  Future<void> removeTag(SearchTag tag) async {
    final key = _findKey(tag.type, tag.name);
    if (key != null) {
      await _box.delete(key);
    }
  }
  Future<void> resetTagsByType(String type) async {
    final keysToDelete = [];
    final map = _box.toMap();
    for (final entry in map.entries) {
      if (entry.value.type == type) {
        keysToDelete.add(entry.key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }
  // 清除全部记录
  Future<void> clearAll() async {
    await _box.clear();
  }

  // 内部辅助函数：通过联合属性查找对应的数据 Key
  dynamic _findKey(String type, String name) {
    final map = _box.toMap();
    for (final entry in map.entries) {
      final currentTag = entry.value;
      if (currentTag.type == type && currentTag.name == name) {
        return entry.key;
      }
    }
    return null;
  }
}