/// 1. 键值对存储接口 (适用于 Settings, Auth, PlayerState)
abstract class IKeyValueStore {
  Future<void> put(String key, dynamic value);
  Future<dynamic> get(String key, {dynamic defaultValue}); // 改为异步
  Future<void> delete(String key);
  Future<void> clear();
}

/// 2. 实体存储接口 (适用于 History, FileNode 等以 ID 为主键的列表数据)
abstract class IEntityStore<T> {
  Future<void> put(dynamic id, T entity);
  Future<void> putAll(Map<dynamic, T> entities);
  Future<T?> get(dynamic id);              // 改为异步
  Future<List<T>> getAll();                // 改为异步
  Future<void> delete(dynamic id);
  Future<void> deleteAll(List<dynamic> ids);
  Future<void> clear();
  Future<int> get length;                  // 改为异步
}