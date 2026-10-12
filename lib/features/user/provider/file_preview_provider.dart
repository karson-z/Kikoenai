import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/charset_cover.dart';

import '../../../../../core/service/site/site_api_provider.dart';

typedef TextContentQuery = ({String inputPath, String? siteId});

final textContentProvider =
    FutureProvider.autoDispose.family<String, TextContentQuery>((
  ref,
  query,
) async {
  final inputPath = query.inputPath;

  try {
    List<int> fileBytes;
    String content;

    // 2. 获取原始字节流 (Bytes)
    if (inputPath.startsWith('http') || inputPath.startsWith('https')) {
      // 网络请求
      final httpClient = query.siteId == null
          ? ref.read(sitesHttpClientProvider)
          : ref.read(siteHttpClientByIdProvider(query.siteId!));
      final response = await httpClient.getBytes(inputPath);
      fileBytes = response.data ?? const <int>[];
      final hintedCharset = FileEncodingHelper.extractCharsetFromContentType(
        response.headers.value('content-type'),
      );
      final fileEncode = await FileEncodingHelper.decodeBytes(
        fileBytes,
        hintedCharset: hintedCharset,
      );
      content = fileEncode.content;
    } else {
      // 本地文件
      final file = File(inputPath);
      if (!file.existsSync()) throw Exception("文件不存在");

      fileBytes = await file.readAsBytes();
      final fileEncode = await FileEncodingHelper.decodeBytes(fileBytes);
      content = fileEncode.content;
    }

    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 1), link.close);
    ref.onDispose(timer.cancel);
    return content;
  } catch (e) {
    throw Exception('读取文件失败: $e');
  }
});
