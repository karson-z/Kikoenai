import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kikoenai/features/album/data/model/work_info.dart';
import '../../../../core/enums/node_type.dart';

part 'file_node.g.dart';

@JsonSerializable()
@HiveType(typeId: 10) // Hive 适配器 ID，确保唯一
class FileNode extends HiveObject {
  @HiveField(0)
  final NodeType type;

  @HiveField(1)
  final String title;

  final List<FileNode>? children;

  @HiveField(2)
  final String? hash;

  @HiveField(3)
  final String? mediaStreamUrl; // 通常作为文件的唯一标识（路径）

  @HiveField(4)
  final String? mediaDownloadUrl;

  @HiveField(5)
  final double? duration;

  @HiveField(6)
  final int? size;

  @HiveField(7)
  final String? workTitle;

  @HiveField(8)
  final WorkInfo? work;

  @HiveField(9)
  final String? artist;

  ///最后修改时间
  @HiveField(10)
  final int lastModified;

  // --- 便捷判断属性 ---
  bool get isFolder => type == NodeType.folder;
  bool get isAudio => type == NodeType.audio;
  bool get isImage => type == NodeType.image;
  bool get isText => type == NodeType.text;
  bool get isVideo => type == NodeType.video;
  bool get isOther => type == NodeType.other;

  /// 辅助属性：获取唯一 ID (使用路径)
  String get keyId => mediaStreamUrl ?? hash ?? "";

  FileNode({
    required this.type,
    required this.title,
    this.children,
    this.hash,
    this.mediaStreamUrl,
    this.mediaDownloadUrl,
    this.duration,
    this.size,
    this.workTitle,
    this.work,
    this.artist,
    this.lastModified = 0, // 默认为 0
  });

  FileNode copyWith({
    NodeType? type,
    String? title,
    List<FileNode>? children,
    String? hash,
    String? mediaStreamUrl,
    String? mediaDownloadUrl,
    double? duration,
    int? size,
    String? workTitle,
    WorkInfo? work,
    String? artist,
    int? lastModified,
  }) {
    return FileNode(
      type: type ?? this.type,
      title: title ?? this.title,
      children: children ?? this.children,
      hash: hash ?? this.hash,
      mediaStreamUrl: mediaStreamUrl ?? this.mediaStreamUrl,
      mediaDownloadUrl: mediaDownloadUrl ?? this.mediaDownloadUrl,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      workTitle: workTitle ?? this.workTitle,
      work: work ?? this.work,
      artist: artist ?? this.artist,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // 自动生成
  factory FileNode.fromJson(Map<String, dynamic> json) =>
      _$FileNodeFromJson(json);

  Map<String, dynamic> toJson() => _$FileNodeToJson(this);
}