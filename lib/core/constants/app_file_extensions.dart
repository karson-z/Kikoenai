class FileExtensions {
  FileExtensions._();

  // --- 1. 基础集合定义 ---

  static const Set<String> archives = {'.zip', '.rar', '.7z', '.tar', '.gz', '.iso', '.tgz'};
  static const Set<String> subtitles = {'.srt', '.ass', '.ssa', '.vtt', '.sub', '.sup', '.smi', '.idx', '.lrc'};
  static const Set<String> images = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.svg', '.tiff'};
  static const Set<String> video = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'};
  static const Set<String> audio = {'.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'};
  static const Set<String> documents = {'.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.csv'};

  // --- 2. 核心判断方法 ---

  /// 通用判断逻辑：提取后缀并校验
  /// 支持传入 完整路径、文件名 或 带点的后缀
  static bool _check(String input, Set<String> set) {
    if (input.isEmpty) return false;
    // 获取最后一个点及其后面的内容，并转为小写
    final String ext = input.contains('.')
        ? input.substring(input.lastIndexOf('.')).toLowerCase()
        : '.$input'.toLowerCase();
    return set.contains(ext);
  }

  static bool isArchive(String path) => _check(path, archives);
  static bool isSubtitle(String path) => _check(path, subtitles);
  static bool isImage(String path) => _check(path, images);
  static bool isVideo(String path) => _check(path, video);
  static bool isAudio(String path) => _check(path, audio);
  static bool isDocument(String path) => _check(path, documents);

  /// 判断是否为可播放媒体 (音频或视频)
  static bool isMedia(String path) => isAudio(path) || isVideo(path);

  // --- 3. 特殊逻辑判断 (SE 后缀) ---

  static const Set<String> seSuffixes = {
    '_se_off', '_se无', '_seなし', '_se無し', '_se有り', '_seあり', '_se有', '_nose',
    '_se', 'se_off', 'se无', 'seなし', 'se無し', 'se有り', 'seあり', 'se有', 'nose',
  };

  /// 判断文件名是否包含特殊的 SE (Sound Effect) 标记
  /// 通常用于判断同人音声等作品是否包含特效音版本
  static bool hasSeTag(String fileName) {
    final nameLower = fileName.toLowerCase();
    // 优先匹配长字段，防止短字段误伤
    // 由于 seSuffixes 是 Set，我们按长度降序检索
    final sortedTags = seSuffixes.toList()..sort((a, b) => b.length.compareTo(a.length));

    for (var tag in sortedTags) {
      if (nameLower.contains(tag.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // --- 4. 组合工具 ---

  /// 合并多个集合
  static Set<String> merge(List<Set<String>> sets) {
    return sets.expand((s) => s).toSet();
  }

  /// 获取文件类型枚举 (可选)
  static FileType getFileType(String path) {
    if (isAudio(path)) return FileType.audio;
    if (isVideo(path)) return FileType.video;
    if (isImage(path)) return FileType.image;
    if (isSubtitle(path)) return FileType.subtitle;
    if (isArchive(path)) return FileType.archive;
    if (isDocument(path)) return FileType.document;
    return FileType.unknown;
  }
}

enum FileType { audio, video, image, subtitle, archive, document, unknown }