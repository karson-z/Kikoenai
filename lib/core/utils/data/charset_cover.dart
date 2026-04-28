import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:charset_converter/charset_converter.dart'; // 引入系统级字符转换

class CharsetCover {
  /// 修复原代码中的同步方法（转为异步）
  static Future<String> fixEncoding(String original) async {
    try {
      // 1. 回退到 Latin-1 字节
      final List<int> bytes = latin1.encode(original);

      // 2. 尝试使用系统底层的 GBK 解码
      final decoded = await CharsetConverter.decode("GBK", Uint8List.fromList(bytes));
      return decoded;
    } catch (e) {
      return original;
    }
  }
}

/// 解码结果封装
class FileDecodingResult {
  final String content;
  final String encoding;

  FileDecodingResult(this.content, this.encoding);

  @override
  String toString() => 'Encoding: $encoding, Content Length: ${content.length}';
}

/// 文件编码处理工具类
class FileEncodingHelper {
  FileEncodingHelper._();

  /// 智能读取文件并检测编码
  static Future<FileDecodingResult> readFile(File file) async {
    try {
      if (!await file.exists()) {
        throw FileSystemException("文件不存在", file.path);
      }
      final bytes = await file.readAsBytes();
      return await decodeBytes(bytes); // 变更为 await
    } catch (e) {
      print('[FileEncodingHelper] 读取文件失败: $e');
      rethrow;
    }
  }

  /// 核心解码逻辑：将字节流转换为字符串 (现在是异步的)
  static Future<FileDecodingResult> decodeBytes(List<int> bytes) async {
    final uint8Bytes = Uint8List.fromList(bytes);

    // 1. 检查 BOM (Byte Order Mark)
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return FileDecodingResult(utf8.decode(bytes.sublist(3)), 'UTF-8');
    }

    if (bytes.length >= 2) {
      // UTF-16LE
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        final data = ByteData.sublistView(uint8Bytes.sublist(2));
        final codeUnits = List.generate(data.lengthInBytes ~/ 2, (i) => data.getUint16(i * 2, Endian.little));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16LE');
      }
      // UTF-16BE
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        final data = ByteData.sublistView(uint8Bytes.sublist(2));
        final codeUnits = List.generate(data.lengthInBytes ~/ 2, (i) => data.getUint16(i * 2, Endian.big));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16BE');
      }
    }

    // 2. 尝试 UTF-8
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      return FileDecodingResult(decoded, 'UTF-8');
    } catch (_) {}

    // 3. 尝试 GBK (甚至也可以尝试 Shift-JIS)
    try {
      final gbkResult = await CharsetConverter.decode("GBK", uint8Bytes);
      // 简单校验一下转换结果是不是乱码 (包含特殊的替换符说明失败了)
      if (gbkResult.isNotEmpty && !gbkResult.contains('')) {
        return FileDecodingResult(gbkResult, 'GBK');
      }
    } catch (_) {}

    // 如果你有解析日文乱码的需求，顺便还可以加上 Shift-JIS！
    try {
      final sjisResult = await CharsetConverter.decode("Shift_JIS", uint8Bytes);
      if (sjisResult.isNotEmpty && !sjisResult.contains('')) {
        return FileDecodingResult(sjisResult, 'Shift-JIS');
      }
    } catch (_) {}

    // 4. 降级到 Latin1
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
        // 使用系统 API 编码
          final encodedBytes = await CharsetConverter.encode("GBK", content);
          bytes = encodedBytes.toList();
          break;
        case 'Shift-JIS':
          final encodedBytes = await CharsetConverter.encode("Shift_JIS", content);
          bytes = encodedBytes.toList();
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

  static List<int> _encodeUtf16(String content, Endian endian) {
    // ... 原逻辑保持不变 ...
    final codeUnits = content.codeUnits;
    final buffer = Uint8List(2 + codeUnits.length * 2);
    final data = ByteData.sublistView(buffer);
    if (endian == Endian.little) {
      data.setUint8(0, 0xFF);
      data.setUint8(1, 0xFE);
    } else {
      data.setUint8(0, 0xFE);
      data.setUint8(1, 0xFF);
    }
    for (int i = 0; i < codeUnits.length; i++) {
      data.setUint16(2 + i * 2, codeUnits[i], endian);
    }
    return buffer.toList();
  }
}