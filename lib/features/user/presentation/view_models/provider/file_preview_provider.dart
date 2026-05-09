import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/charset_cover.dart';

import '../../../../../core/utils/network/api_client.dart';

final textContentProvider =
    FutureProvider.family<String, String>((ref, inputPath) async {
  // 1. 缓存管理：保持 1 分钟
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 1), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  try {
    List<int> fileBytes;

    // 2. 获取原始字节流 (Bytes)
    if (inputPath.startsWith('http') || inputPath.startsWith('https')) {
      // 网络请求
      final api = ref.read(apiClientProvider);
      final response = await api.getBytes(inputPath);
      fileBytes = response.data ?? const <int>[];
      final hintedCharset = FileEncodingHelper.extractCharsetFromContentType(
        response.headers.value('content-type'),
      );
      final fileEncode = await FileEncodingHelper.decodeBytes(
        fileBytes,
        hintedCharset: hintedCharset,
      );
      return fileEncode.content;
    } else {
      // 本地文件
      final file = File(inputPath);
      if (!file.existsSync()) throw Exception("文件不存在");

      fileBytes = await file.readAsBytes();
    }
    final fileEncode = await FileEncodingHelper.decodeBytes(fileBytes);
    // 3. 调用智能解码函数
    return fileEncode.content;
  } catch (e) {
    throw Exception('读取文件失败: $e');
  }
});
