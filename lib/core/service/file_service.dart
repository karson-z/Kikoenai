import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 用于记录已成功导入（复制）的源文件路径
class FileService {
  static const String _recordFileName = 'imported_source_files.json';

  /// 获取记录文件
  static Future<File> _getRecordFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_recordFileName');
  }

  /// 追加记录一个文件路径
  static Future<void> record(String sourcePath) async {
    try {
      final file = await _getRecordFile();
      List<String> currentRecords = [];

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          currentRecords = List<String>.from(jsonDecode(content));
        }
      }

      // 避免重复记录
      if (!currentRecords.contains(sourcePath)) {
        currentRecords.add(sourcePath);
        await file.writeAsString(jsonEncode(currentRecords));
        print("已记录源文件待清理: $sourcePath");
      }
    } catch (e) {
      print("记录缓存失败: $e");
    }
  }

  /// 获取所有待清理的源文件列表 (用于 UI 展示)
  static Future<List<String>> getRecordedPaths() async {
    try {
      final file = await _getRecordFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      return List<String>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  /// 清空记录 (当用户在 UI 点击“清理完毕”后调用)
  static Future<void> clearRecords() async {
    final file = await _getRecordFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
  static Future<void> overwriteRecords(List<String> newPaths) async {
    try {
      final file = await _getRecordFile();
      // 直接将内存中最新的 list 覆盖写入文件
      await file.writeAsString(jsonEncode(newPaths));
    } catch (e) {
      print("更新记录失败: $e");
    }
  }
}