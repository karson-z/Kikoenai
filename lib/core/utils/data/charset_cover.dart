import 'dart:convert';
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