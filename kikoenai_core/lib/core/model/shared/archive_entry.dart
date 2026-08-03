class ArchiveEntry {
  final String virtualPath; // 这种路径现在看起来像: /storage/emulated/0/subs.zip/folder/a.srt
  final String name;
  final int size;

  ArchiveEntry({
    required this.virtualPath,
    required this.name,
    this.size = 0,
  });
}