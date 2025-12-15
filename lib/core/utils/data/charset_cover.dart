import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fast_gbk/fast_gbk.dart'; // 引入 gbk

class CharsetCover {
  static String fixEncoding(String original) {
    try {
      // 1. 尝试检测是否已经是正常的 UTF-8 (防止把本来正常的英文或UTF-8中文搞乱)
      // 这一步是经验性的，如果本来就是 UTF-8，通常不需要处理
      // 但因为 archive 包内部逻辑，有时我们需要先回退到字节

      // 核心逻辑：
      // archive 包如果没有识别出 UTF-8，通常会保留原始字节映射在 Latin-1 范围内
      // 我们将其还原为字节
      final List<int> bytes = latin1.encode(original);

      // 2. 尝试使用 GBK 解码
      return gbk.decode(bytes);
    } catch (e) {
      // 如果转换失败（例如它确实是 UTF-8 或者其他情况），返回原字符串
      return original;
    }
  }
}

/// 解码结果封装
class FileDecodingResult {
  final String content;
  final String encoding; // 'UTF-8', 'GBK', 'Shift-JIS', 'UTF-16LE', etc.

  FileDecodingResult(this.content, this.encoding);

  @override
  String toString() => 'Encoding: $encoding, Content Length: ${content.length}';
}

/// 文件编码处理工具类
class FileEncodingHelper {
  // 私有构造函数，防止实例化
  FileEncodingHelper._();

  /// 智能读取文件并检测编码
  static Future<FileDecodingResult> readFile(File file) async {
    try {
      if (!await file.exists()) {
        throw FileSystemException("文件不存在", file.path);
      }
      final bytes = await file.readAsBytes();
      return decodeBytes(bytes);
    } catch (e) {
      print('[FileEncodingHelper] 读取文件失败: $e');
      rethrow;
    }
  }

  /// 核心解码逻辑：将字节流转换为字符串
  static FileDecodingResult decodeBytes(List<int> bytes) {
    // 1. 检查 BOM (Byte Order Mark)
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return FileDecodingResult(utf8.decode(bytes.sublist(3)), 'UTF-8');
    }

    if (bytes.length >= 2) {
      // UTF-16LE (FF FE)
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(2)));
        final codeUnits = List.generate(data.lengthInBytes ~/ 2, (i) => data.getUint16(i * 2, Endian.little));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16LE');
      }
      // UTF-16BE (FE FF)
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(2)));
        final codeUnits = List.generate(data.lengthInBytes ~/ 2, (i) => data.getUint16(i * 2, Endian.big));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16BE');
      }
    }

    // 2. 尝试 UTF-8 (最严格，优先尝试)
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      return FileDecodingResult(decoded, 'UTF-8');
    } catch (_) {}

    // 3. 竞争检测：Shift-JIS vs GBK

    // A. 尝试 Shift-JIS
    String? sjisResult;
    bool sjisSuccess = false;
    /* // 需要引入相关库
    try {
      sjisResult = ShiftJis().decode(bytes);
      // 简单启发式：如果不包含乱码占位符，且长度合理
      sjisSuccess = !sjisResult.contains('');
    } catch (_) {}
    */

    // B. 尝试 GBK
    String? gbkResult;
    bool gbkSuccess = false;
    try {
      gbkResult = gbk.decode(bytes);
      // fast_gbk 可能会把无法识别的字节转为空或问号，需根据实际情况判断
      gbkSuccess = !gbkResult.contains('');
    } catch (_) {}

    // 决策逻辑
    if (sjisSuccess) return FileDecodingResult(sjisResult!, 'Shift-JIS');
    if (gbkSuccess && gbkResult != null) return FileDecodingResult(gbkResult, 'GBK');

    // 4. 降级到 Latin1 (原样输出)
    return FileDecodingResult(latin1.decode(bytes), 'Latin1');
  }

  /// 保存文件 (尝试使用指定编码)
  static Future<void> saveFile(File file, String content, String encoding) async {
    List<int> bytes;
    try {
      switch (encoding) {
        case 'UTF-16LE':
          bytes = _encodeUtf16(content, Endian.little);
          break;
        case 'UTF-16BE':
          bytes = _encodeUtf16(content, Endian.big);
          break;
        case 'GBK':
          bytes = gbk.encode(content);
          break;
        case 'Shift-JIS':
        // bytes = ShiftJis().encode(content);
        // 暂时回退到 UTF-8，直到引入 Shift-JIS 库
          print('[FileEncodingHelper] Shift-JIS 库未集成，回退到 UTF-8');
          bytes = utf8.encode(content);
          break;
        case 'Latin1':
          bytes = latin1.encode(content);
          break;
        case 'UTF-8':
        default:
          bytes = utf8.encode(content);
      }
    } catch (e) {
      print('[FileEncodingHelper] 编码转换失败 ($encoding)，回退到 UTF-8: $e');
      bytes = utf8.encode(content);
    }

    await file.writeAsBytes(bytes);
  }

  /// 内部辅助：处理 UTF-16 编码逻辑
  static List<int> _encodeUtf16(String content, Endian endian) {
    final codeUnits = content.codeUnits;
    // 2 bytes per char + 2 bytes BOM
    final buffer = Uint8List(2 + codeUnits.length * 2);
    final data = ByteData.sublistView(buffer);

    // 设置 BOM
    if (endian == Endian.little) {
      data.setUint8(0, 0xFF);
      data.setUint8(1, 0xFE);
    } else {
      data.setUint8(0, 0xFE);
      data.setUint8(1, 0xFF);
    }

    // 填充内容
    for (int i = 0; i < codeUnits.length; i++) {
      // 偏移量 2 (BOM) + index * 2
      data.setUint16(2 + i * 2, codeUnits[i], endian);
    }
    return buffer;
  }
}