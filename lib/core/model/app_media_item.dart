import 'dart:typed_data';
// 如果你想在 operator== 中比较图片内容的相等性，需要引入此库
// import 'package:flutter/foundation.dart';

class AppMediaItem {
  final String path;
  final String fileName;
  final String title;
  final String artist;
  final String album;
  final double durationSeconds;

  // 图片数据 (二进制)
  final Uint8List? coverBytes;

  const AppMediaItem({
    required this.path,
    required this.fileName,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    this.coverBytes,
  });

  // --- 1. 反序列化 (JSON -> Object) ---
  factory AppMediaItem.fromJson(Map<String, dynamic> json) {
    return AppMediaItem(
      path: json['path'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      durationSeconds: (json['durationSeconds'] as num).toDouble(),

      // 修改重点：处理二进制数据
      // JSON 中的数组读出来是 List<dynamic>，需要先转为 List<int>，再转为 Uint8List
      coverBytes: json['coverBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['coverBytes']))
          : null,
    );
  }

  // --- 2. 序列化 (Object -> JSON) ---
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fileName': fileName,
      'title': title,
      'artist': artist,
      'album': album,
      'durationSeconds': durationSeconds,

      // 修改重点：Uint8List 本质是 List<int>，jsonEncode 可以直接处理
      // 但为了保险起见，有时会调用 .toList() 确保其为标准 List
      'coverBytes': coverBytes,
    };
  }

  // --- 辅助 Getter ---
  Duration get duration => Duration(milliseconds: (durationSeconds * 1000).toInt());

  // --- 3. CopyWith (需添加 coverBytes) ---
  AppMediaItem copyWith({
    String? path,
    String? fileName,
    String? title,
    String? artist,
    String? album,
    double? durationSeconds,
    Uint8List? coverBytes, // 新增参数
  }) {
    return AppMediaItem(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      coverBytes: coverBytes ?? this.coverBytes, // 新增赋值
    );
  }

  @override
  String toString() {
    // 不打印 coverBytes，因为数据太长了
    return 'AppMediaItem(title: $title, artist: $artist, path: $path, hasCover: ${coverBytes != null})';
  }

  // --- 4. 相等性比较 ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppMediaItem &&
        other.path == path &&
        other.fileName == fileName &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.durationSeconds == durationSeconds &&
        // 注意：这里只比较了引用是否相同。
        // 如果需要比较图片内容是否完全一致，需要使用 listEquals(other.coverBytes, coverBytes)
        // 但考虑到性能（图片数据很大），通常不建议在 == 中逐字节比较图片。
        other.coverBytes == coverBytes;
  }

  // --- 5. HashCode ---
  @override
  int get hashCode {
    return path.hashCode ^
    fileName.hashCode ^
    title.hashCode ^
    artist.hashCode ^
    album.hashCode ^
    durationSeconds.hashCode ^
    coverBytes.hashCode;
  }
}