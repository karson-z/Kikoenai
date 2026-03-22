import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../constants/app_typeIds.dart';

part 'file_node.g.dart';

@HiveType(typeId: TypeIds.nodeType)
enum NodeType {
  @HiveField(0)
  folder,
  @HiveField(1)
  audio,
  @HiveField(2)
  image,
  @HiveField(3)
  text,
  @HiveField(4)
  video,
  @HiveField(5)
  other,
  @HiveField(6)
  unknown,
}
// 基础枚举结构，保留 Hive 注解
@HiveType(typeId: TypeIds.nodeStatus)
enum NodeStatus {
  @HiveField(0)
  normal,

  @HiveField(1)
  pending,  // 扫描发现，等待用户确认加入队列

  @HiveField(2)
  parsing,  // 正在发起网络请求爬取中

  @HiveField(3)
  parsed;   // 爬取完成


  /// 扩展一些常用的状态判断，提升代码可读性
  bool get isPending => this == NodeStatus.pending;
  bool get isProcessing => this == NodeStatus.parsing;
  bool get isCompleted => this == NodeStatus.parsed;
}

@JsonSerializable()
@HiveType(typeId: TypeIds.fileNode) // Hive 适配器 ID，确保唯一
class FileNode extends HiveObject {
  @HiveField(0)
  final NodeType type;

  @HiveField(1)
  final String title;

  List<FileNode>? children;

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
  final String? artist;

  ///最后修改时间
  @HiveField(9)
  final int lastModified;

  /// 解析状态标志位
  @HiveField(10)
  final NodeStatus nodeStatus;

  /// 关联的作品 RJ 码
  @HiveField(11)
  final String? rjCode;

  // --- 便捷判断属性 ---
  bool get isFolder => type == NodeType.folder;
  bool get isAudio => type == NodeType.audio;
  bool get isImage => type == NodeType.image;
  bool get isText => type == NodeType.text;
  bool get isVideo => type == NodeType.video;
  bool get isOther => type == NodeType.other;

  /// 辅助属性：获取唯一 ID (使用路径)
  String get keyId => mediaStreamUrl ?? hash ?? "";

  bool get isLocal {
    final url = mediaStreamUrl;
    if (url == null || url.isEmpty) return false;

    // 处理标准 URI 格式
    if (url.startsWith('file://')) return true;

    // 处理常见的网络协议
    if (url.startsWith('http://') || url.startsWith('https://')) return false;

    // 兜底逻辑：在移动端/桌面端，绝对路径通常以 / 开头，且不包含网络特征
    return url.startsWith('/');
  }

  /// 判断是否为远程网络文件
  bool get isRemote => !isLocal && (mediaStreamUrl?.startsWith('http') ?? false);
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
    this.artist,
    this.lastModified = 0, // 默认为 0
    this.nodeStatus = NodeStatus.normal, // 默认状态
    this.rjCode,
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
    String? artist,
    int? lastModified,
    NodeStatus? nodeStatus,
    String? rjCode,
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
      artist: artist ?? this.artist,
      lastModified: lastModified ?? this.lastModified,
      nodeStatus: nodeStatus ?? this.nodeStatus,
      rjCode: rjCode ?? this.rjCode,
    );
  }
  // 自动生成
  factory FileNode.fromJson(Map<String, dynamic> json) =>
      _$FileNodeFromJson(json);

  Map<String, dynamic> toJson() => _$FileNodeToJson(this);
}