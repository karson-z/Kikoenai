import 'package:json_annotation/json_annotation.dart';
import '../../../../core/enums/node_type.dart';

part 'file_node.g.dart';

@JsonSerializable()
class FileNode {
  final NodeType type;
  final String title;
  final List<FileNode>? children;
  final String? hash;
  final String? mediaStreamUrl;
  final String? mediaDownloadUrl;
  final double? duration;
  final int? size;

  // --- 便捷判断属性 ---
  bool get isFolder => type == NodeType.folder;
  bool get isAudio => type == NodeType.audio;
  bool get isImage => type == NodeType.image;
  bool get isText => type == NodeType.text;

  FileNode({
    required this.type,
    required this.title,
    this.children,
    this.hash,
    this.mediaStreamUrl,
    this.mediaDownloadUrl,
    this.duration,
    this.size,
  });

  // 自动生成
  factory FileNode.fromJson(Map<String, dynamic> json) =>
      _$FileNodeFromJson(json);

  Map<String, dynamic> toJson() => _$FileNodeToJson(this);
}
