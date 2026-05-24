import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';
// 确保引入了 ScanMode 所在的正确路径
import 'package:kikoenai/core/service/file/file_scanner_service.dart';

class ScanModeAdapter extends TypeAdapter<ScanMode> {
  /// Hive 内部类型标识符。请在 TypeIds 统一管理类中进行登记，避免与其他对象冲突。
  @override
  final int typeId = TypeIds.scanMode; // 假设 2 未被占用，请根据实际情况进行调整

  @override
  ScanMode read(BinaryReader reader) {
    // 读取写入的整型索引并还原为枚举
    final index = reader.readInt();
    return ScanMode.values[index];
  }

  @override
  void write(BinaryWriter writer, ScanMode obj) {
    // 将枚举的 index (0, 1, 2) 作为 int 写入二进制流
    writer.writeInt(obj.index);
  }
}