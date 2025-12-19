
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/features/album/data/model/work_info.dart';

class WorkInfoAdapter extends TypeAdapter<WorkInfo> {
  @override
  final int typeId = 5; // 确保不与 PlayerState(3) 或 FileNode(4) 冲突

  @override
  WorkInfo read(BinaryReader reader) {
    // 1. 读取必须字段
    final id = reader.readInt();

    // 2. 读取可空字段 (使用 dynamic read 并强转)
    final sourceType = reader.read() as String?;
    final sourceId = reader.read() as String?;

    return WorkInfo(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  @override
  void write(BinaryWriter writer, WorkInfo obj) {
    // 写入顺序必须与读取顺序一致
    writer.writeInt(obj.id);

    // Hive 的 write() 方法会自动处理 String? 的 null 情况
    writer.write(obj.sourceType);
    writer.write(obj.sourceId);
  }
}