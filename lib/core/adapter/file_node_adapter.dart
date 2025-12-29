

import 'package:hive_ce/hive.dart';

import '../../features/album/data/model/file_node.dart';
import '../../features/album/data/model/work_info.dart';
import '../enums/node_type.dart';

class FileNodeAdapter extends TypeAdapter<FileNode> {
  @override
  final int typeId = 4;

  @override
  FileNode read(BinaryReader reader) {
    // 1. 读取 Enum (作为索引)
    final typeIndex = reader.readInt();
    final type = NodeType.values[typeIndex];

    // 2. 读取非空字段
    final title = reader.readString();

    // 3. 读取可空字段 (使用 dynamic read 自动处理 null)
    final children = (reader.read() as List?)?.cast<FileNode>();
    final hash = reader.read() as String?;
    final mediaStreamUrl = reader.read() as String?;
    final mediaDownloadUrl = reader.read() as String?;
    final duration = reader.read() as double?;
    final size = reader.read() as int?;
    final workTitle = reader.read() as String?;

    // ️ WorkInfo 必须也有自己的 Adapter 并已注册
    final work = reader.read() as WorkInfo?;

    return FileNode(
      type: type,
      title: title,
      children: children,
      hash: hash,
      mediaStreamUrl: mediaStreamUrl,
      mediaDownloadUrl: mediaDownloadUrl,
      duration: duration,
      size: size,
      workTitle: workTitle,
      work: work,
    );
  }

  @override
  void write(BinaryWriter writer, FileNode obj) {
    // 1. 写入 Enum 索引
    writer.writeInt(obj.type.index);

    // 2. 写入非空字段
    writer.writeString(obj.title);

    // 3. 写入可空字段
    // Hive 的 write() 方法会自动处理 null 和 List 类型
    writer.write(obj.children);
    writer.write(obj.hash);
    writer.write(obj.mediaStreamUrl);
    writer.write(obj.mediaDownloadUrl);
    writer.write(obj.duration);
    writer.write(obj.size);
    writer.write(obj.workTitle);
    writer.write(obj.work);
  }
}