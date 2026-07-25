import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:charset_converter/charset_converter.dart'; // 引入系统级字符转换

typedef CharsetDecodeHandler = Future<String> Function(
  String charset,
  Uint8List bytes,
);

class CharsetCover {
  /// 修复原代码中的同步方法（转为异步）
  static Future<String> fixEncoding(String original) async {
    try {
      // 1. 回退到 Latin-1 字节
      final List<int> bytes = latin1.encode(original);

      // 2. 尝试使用系统底层的 GBK 解码
      final decoded =
          await CharsetConverter.decode("GBK", Uint8List.fromList(bytes));
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

  static CharsetDecodeHandler _charsetDecodeHandler = CharsetConverter.decode;
  static const String _replacementChar = '\uFFFD';

  static void debugSetCharsetDecodeHandler(CharsetDecodeHandler handler) {
    _charsetDecodeHandler = handler;
  }

  static void debugResetCharsetDecodeHandler() {
    _charsetDecodeHandler = CharsetConverter.decode;
  }

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

  static String? extractCharsetFromContentType(String? contentType) {
    if (contentType == null || contentType.trim().isEmpty) return null;

    final match = RegExp(
      "charset\\s*=\\s*[\"']?([^;\"'\\s]+)",
      caseSensitive: false,
    ).firstMatch(contentType);

    if (match == null) return null;
    return normalizeCharset(match.group(1));
  }

  static String? normalizeCharset(String? charset) {
    if (charset == null || charset.trim().isEmpty) return null;

    final normalized = charset.trim().toLowerCase();
    switch (normalized) {
      case 'utf8':
      case 'utf-8':
        return 'UTF-8';
      case 'utf16':
      case 'utf-16':
        return 'UTF-16';
      case 'utf-16le':
        return 'UTF-16LE';
      case 'utf-16be':
        return 'UTF-16BE';
      case 'gb18030':
      case 'gb-18030':
      case 'gb2312':
      case 'gb-2312':
        return 'GB18030';
      case 'gbk':
      case 'cp936':
      case 'ms936':
        return 'GBK';
      case 'shift-jis':
      case 'shift_jis':
      case 'sjis':
      case 'cp932':
      case 'windows-31j':
      case 'ms_kanji':
        return 'Shift_JIS';
      case 'euc-jp':
      case 'euc_jp':
        return 'EUC-JP';
      case 'iso-8859-1':
      case 'latin1':
      case 'latin-1':
        return 'Latin1';
      default:
        return charset.trim();
    }
  }

  /// 核心解码逻辑：将字节流转换为字符串 (现在是异步的)
  static Future<FileDecodingResult> decodeBytes(
    List<int> bytes, {
    String? hintedCharset,
  }) async {
    if (bytes.isEmpty) {
      return FileDecodingResult('', 'EMPTY');
    }

    final uint8Bytes = Uint8List.fromList(bytes);

    // 1. 检查 BOM (Byte Order Mark)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return FileDecodingResult(utf8.decode(bytes.sublist(3)), 'UTF-8');
    }

    if (bytes.length >= 2) {
      // UTF-16LE
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        final data = ByteData.sublistView(uint8Bytes.sublist(2));
        final codeUnits = List.generate(data.lengthInBytes ~/ 2,
            (i) => data.getUint16(i * 2, Endian.little));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16LE');
      }
      // UTF-16BE
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        final data = ByteData.sublistView(uint8Bytes.sublist(2));
        final codeUnits = List.generate(
            data.lengthInBytes ~/ 2, (i) => data.getUint16(i * 2, Endian.big));
        return FileDecodingResult(String.fromCharCodes(codeUnits), 'UTF-16BE');
      }
    }

    final normalizedHint = normalizeCharset(hintedCharset);
    if (normalizedHint != null) {
      final hintedResult = await _tryDecodeWithCharset(normalizedHint, bytes);
      if (hintedResult != null && _looksReadable(hintedResult.content)) {
        return hintedResult;
      }
    }

    // 2. 优先尝试 UTF-8
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      return FileDecodingResult(decoded, 'UTF-8');
    } catch (_) {}

    final utf16WithoutBom = _tryDecodeUtf16WithoutBom(uint8Bytes);
    if (utf16WithoutBom != null) {
      return utf16WithoutBom;
    }

    // 3. 对中日文常见编码做候选评分
    final candidates = <FileDecodingResult>[];
    final candidateCharsets = <String>[
      'GB18030',
      'GBK',
      'Shift_JIS',
      'EUC-JP',
      'Latin1',
    ];

    for (final charset in candidateCharsets) {
      if (charset == normalizedHint) continue;
      final result = await _tryDecodeWithCharset(charset, bytes);
      if (result != null) {
        candidates.add(result);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort(
        (a, b) => _scoreDecodedText(b.content)
            .compareTo(_scoreDecodedText(a.content)),
      );

      final best = candidates.first;
      if (_looksReadable(best.content)) {
        return best;
      }
    }

    // 4. 降级到 Latin1
    return FileDecodingResult(latin1.decode(bytes), 'Latin1');
  }

  /// 保存文件 (尝试使用指定编码)
  static Future<void> saveFile(
      File file, String content, String encoding) async {
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
          final encodedBytes =
              await CharsetConverter.encode("Shift_JIS", content);
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

  static Future<FileDecodingResult?> _tryDecodeWithCharset(
    String charset,
    List<int> bytes,
  ) async {
    try {
      switch (charset) {
        case 'UTF-8':
          return FileDecodingResult(
            utf8.decode(bytes, allowMalformed: false),
            'UTF-8',
          );
        case 'UTF-16':
          return _tryDecodeUtf16WithoutBom(Uint8List.fromList(bytes));
        case 'UTF-16LE':
          return _decodeUtf16(bytes, Endian.little, 'UTF-16LE');
        case 'UTF-16BE':
          return _decodeUtf16(bytes, Endian.big, 'UTF-16BE');
        case 'Latin1':
          return FileDecodingResult(latin1.decode(bytes), 'Latin1');
        default:
          final decoded = await _charsetDecodeHandler(
            charset,
            Uint8List.fromList(bytes),
          );
          if (decoded.isEmpty && bytes.isNotEmpty) return null;
          return FileDecodingResult(decoded, charset);
      }
    } catch (_) {
      return null;
    }
  }

  static FileDecodingResult? _tryDecodeUtf16WithoutBom(Uint8List bytes) {
    if (bytes.length < 4 || bytes.length.isOdd) return null;

    final evenZeroCount = _countZeroBytes(bytes, startIndex: 0);
    final oddZeroCount = _countZeroBytes(bytes, startIndex: 1);
    final threshold = bytes.length ~/ 4;

    if (oddZeroCount >= threshold) {
      return _decodeUtf16(bytes, Endian.little, 'UTF-16LE');
    }

    if (evenZeroCount >= threshold) {
      return _decodeUtf16(bytes, Endian.big, 'UTF-16BE');
    }

    return null;
  }

  static FileDecodingResult _decodeUtf16(
    List<int> bytes,
    Endian endian,
    String encoding,
  ) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final codeUnits = List.generate(
      data.lengthInBytes ~/ 2,
      (i) => data.getUint16(i * 2, endian),
    );
    return FileDecodingResult(String.fromCharCodes(codeUnits), encoding);
  }

  static int _countZeroBytes(Uint8List bytes, {required int startIndex}) {
    int count = 0;
    for (int i = startIndex; i < bytes.length; i += 2) {
      if (bytes[i] == 0) {
        count++;
      }
    }
    return count;
  }

  static bool _looksReadable(String text) {
    if (text.isEmpty) return true;
    return _scoreDecodedText(text) >= text.runes.length ~/ 2;
  }

  static int _scoreDecodedText(String text) {
    if (text.isEmpty) return 0;

    int score = 0;
    for (final rune in text.runes) {
      if (rune == 0x0000) {
        score -= 20;
        continue;
      }

      if (rune == _replacementChar.runes.first) {
        score -= 20;
        continue;
      }

      if (_isControl(rune)) {
        score -= 8;
        continue;
      }

      if (_isAsciiReadable(rune)) {
        score += 2;
        continue;
      }

      if (_isJapaneseKana(rune)) {
        score += 5;
        continue;
      }

      if (_isCjk(rune)) {
        score += 4;
        continue;
      }

      if (_isCjkPunctuation(rune)) {
        score += 3;
        continue;
      }

      if (_isLatin1Supplement(rune)) {
        score -= 2;
        continue;
      }

      score += 1;
    }
    return score;
  }

  static bool _isControl(int rune) {
    if (rune == 0x09 || rune == 0x0A || rune == 0x0D) return false;
    return rune < 0x20 || (rune >= 0x7F && rune <= 0x9F);
  }

  static bool _isAsciiReadable(int rune) {
    return rune == 0x09 ||
        rune == 0x0A ||
        rune == 0x0D ||
        (rune >= 0x20 && rune <= 0x7E);
  }

  static bool _isCjk(int rune) {
    return (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF);
  }

  static bool _isJapaneseKana(int rune) {
    return (rune >= 0x3040 && rune <= 0x309F) ||
        (rune >= 0x30A0 && rune <= 0x30FF) ||
        (rune >= 0xFF66 && rune <= 0xFF9D);
  }

  static bool _isCjkPunctuation(int rune) {
    return (rune >= 0x3000 && rune <= 0x303F) ||
        (rune >= 0xFF00 && rune <= 0xFFEF);
  }

  static bool _isLatin1Supplement(int rune) {
    return rune >= 0x00A0 && rune <= 0x00FF;
  }
}
