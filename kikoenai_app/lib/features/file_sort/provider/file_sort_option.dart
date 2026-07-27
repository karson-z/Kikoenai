import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';

/// 文件树排序字段
enum FileSortField {
  title,
  titleNumber,
  duration,
  size,
}

/// 文件树排序配置（不可变）
class FileSortOption {
  final FileSortField field;
  final bool descending;

  const FileSortOption({
    this.field = FileSortField.title,
    this.descending = false,
  });

  static const FileSortOption defaultOption = FileSortOption();

  FileSortOption copyWith({
    FileSortField? field,
    bool? descending,
  }) {
    return FileSortOption(
      field: field ?? this.field,
      descending: descending ?? this.descending,
    );
  }

  /// 从 Hive Box 读取
  factory FileSortOption.fromStorage(Box<dynamic> box) {
    final fieldIndex = box.get(StorageKeys.fileSortField) as int?;
    final descending = box.get(StorageKeys.fileSortDescending) as bool? ?? false;
    return FileSortOption(
      field: fieldIndex != null && fieldIndex < FileSortField.values.length
          ? FileSortField.values[fieldIndex]
          : FileSortField.title,
      descending: descending,
    );
  }

  /// 写入 Hive Box
  void saveToStorage(Box<dynamic> box) {
    box.put(StorageKeys.fileSortField, field.index);
    box.put(StorageKeys.fileSortDescending, descending);
  }

  @override
  String toString() => 'FileSortOption(field: $field, descending: $descending)';
}
