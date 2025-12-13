class FileExtensions {
  // 私有构造函数，防止实例化
  FileExtensions._();


  /// 压缩包类型
  /// 注意：archive 库默认对 rar/7z 支持有限，需确认解码器支持情况
  static const Set<String> archives = {
    '.zip', '.rar', '.7z', '.tar', '.gz', '.iso', '.tgz'
  };

  /// 字幕文件
  static const Set<String> subtitles = {
    '.srt', '.ass', '.ssa', '.vtt', '.sub', '.sup', '.smi', '.idx','.lrc'
  };

  /// 图片文件
  static const Set<String> images = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.svg', '.tiff'
  };

  /// 视频文件
  static const Set<String> video = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'
  };

  /// 音频文件
  static const Set<String> audio = {
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'
  };

  /// 文档文件
  static const Set<String> documents = {
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.csv'
  };
  static const Set<String> seSuffixes = {
    // 建议：较长的后缀放在前面（虽然Set主要用于查找，但在某些迭代逻辑中顺序很重要）
    '_se_off',
    '_se无',
    '_seなし',
    '_se無し',
    '_se有り',
    '_seあり',
    '_se有',
    '_nose',

    // 短后缀
    '_se',

    // 无下划线版本
    'se_off',
    'se无',
    'seなし',
    'se無し',
    'se有り',
    'seあり',
    'se有',
    'nose',
  };
  // --- 3. 组合助手 ---

  /// 合并多个集合 (例如：视频 + 字幕)
  static Set<String> merge(List<Set<String>> sets) {
    final Set<String> result = {};
    for (var s in sets) {
      result.addAll(s);
    }
    return result;
  }
}