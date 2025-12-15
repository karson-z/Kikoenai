
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/charset_cover.dart';

import '../../../../../core/utils/network/api_client.dart';

final textContentProvider = FutureProvider.family<String, String>((ref, inputPath) async {
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

      // 【关键】必须指定 ResponseType.bytes，否则 Dio 会尝试自动解码导致乱码
      final response = await api.get<List<int>>(
        inputPath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) throw Exception("下载内容为空");
      fileBytes = response.data!;

    } else {
      // 本地文件
      final file = File(inputPath);
      if (!file.existsSync()) throw Exception("文件不存在");

      fileBytes = await file.readAsBytes();
    }
    final fileEncode = FileEncodingHelper.decodeBytes(fileBytes);
    // 3. 调用智能解码函数
    return fileEncode.content;

  } catch (e) {
    throw Exception('读取文件失败: $e');
  }
});