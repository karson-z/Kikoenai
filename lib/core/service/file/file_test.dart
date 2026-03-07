import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'file_scanner_storage.dart';

class ScannerDebugUtils {
  /// 读取并打印 Hive 中所有的扫描数据
  static void dumpDiskData() {
    final storage = FileScannerStorage();
    final allNodes = storage.getAll(); // 获取磁盘中的所有扁平数据

    debugPrint('\n========== 📦 Hive 磁盘数据分析开始 ==========');
    debugPrint('总记录数: ${allNodes.length} 条');

    // --- [新增] 专门筛选出 pending (待解析) 状态的节点 ---
    final pendingNodes = allNodes.where((n) => n.nodeStatus == NodeStatus.pending).toList();
    debugPrint('\n⏳ 待解析节点 [Pending] (${pendingNodes.length}个):');
    for (var p in pendingNodes) {
      final rjStr = p.rjCode != null ? '[${p.rjCode}]' : '[无RJ码]';
      debugPrint('  - 🎯 $rjStr | 名称: ${p.title}');
      debugPrint('       路径: ${p.mediaStreamUrl}');
    }

    // 1. 筛选出文件夹节点
    final folders = allNodes.where((n) => n.isFolder).toList();
    debugPrint('\n📂 文件夹节点总计 (${folders.length}个):');
    for (var f in folders) {
      // 使用 .name 获取基础枚举的字符串表示 (例如输出 "normal" 或 "pending")
      final statusLabel = f.nodeStatus.name;
      final rjStr = f.rjCode != null ? '[${f.rjCode}]' : '[无RJ码]';
      debugPrint('  - 📁 状态: $statusLabel | $rjStr | 名称: ${f.title}');
      debugPrint('       路径: ${f.mediaStreamUrl}');
    }

    // 2. 筛选出普通文件节点
    final files = allNodes.where((n) => !n.isFolder).toList();
    debugPrint('\n📄 媒体文件节点总计 (${files.length}个):');
    for (var f in files) {
      debugPrint('  - 🎵 ${f.title}');
      debugPrint('       路径: ${f.mediaStreamUrl}');
    }

    debugPrint('========== 📦 Hive 磁盘数据分析结束 ==========\n');
  }
}
void main () {
  AppStorage.init();
  ScannerDebugUtils.dumpDiskData();
}