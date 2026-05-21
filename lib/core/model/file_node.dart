import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import '../constants/app_typeIds.dart';

part 'file_node.freezed.dart';
part 'file_node.g.dart';

@HiveType(typeId: TypeIds.nodeSource)
enum NodeSource {
  @HiveField(0) asmrServer,   // ASMR 服务器
  @HiveField(1) localWork,    // 本地作品（拥有所属作品元数据）
  @HiveField(2) localSingle,  // 本地单曲（无作品元数据依赖）
  @HiveField(3) cloudDrive;   // 网盘媒体
}

@HiveType(typeId: TypeIds.nodeType)
enum NodeType {
  @HiveField(0) folder,
  @HiveField(1) audio,
  @HiveField(2) image,
  @HiveField(3) text,
  @HiveField(4) video,
  @HiveField(5) other,
  @HiveField(6) unknown;
}

@HiveType(typeId: TypeIds.nodeStatus)
enum NodeStatus {
  @HiveField(0) normal,
  @HiveField(1) pending,
  @HiveField(2) parsing,
  @HiveField(3) parsed;

  bool get isPending => this == NodeStatus.pending;
  bool get isProcessing => this == NodeStatus.parsing;
  bool get isCompleted => this == NodeStatus.parsed;
}

@freezed
@HiveType(typeId: TypeIds.fileNode, adapterName: 'FileNodeAdapter')
abstract class FileNode extends HiveObject with _$FileNode {
  factory FileNode({
    @HiveField(0) required NodeType type,
    @HiveField(1) required String title,
    List<FileNode>? children,
    @HiveField(2) String? hash,
    @HiveField(3) String? mediaStreamUrl,
    @HiveField(4) String? mediaDownloadUrl,
    @HiveField(5) double? duration,
    @HiveField(6) int? size,
    @HiveField(7) String? workTitle,
    @HiveField(8) String? artist,
    @HiveField(9) @Default(0) int lastModified,
    @HiveField(10) @Default(NodeStatus.normal) NodeStatus nodeStatus,
    @HiveField(11) int? workId, // 该文件节点所属作品的唯一标识 ID
    @HiveField(12) required NodeSource source, // 必须在出生时决定的具体业务来源
  }) = _FileNode;

   FileNode._();

  bool get isFolder => type == NodeType.folder;
  bool get isAudio => type == NodeType.audio;
  bool get isImage => type == NodeType.image;
  bool get isText => type == NodeType.text;
  bool get isVideo => type == NodeType.video;
  bool get isOther => type == NodeType.other;

  String get keyId => mediaStreamUrl ?? hash ?? "";

  bool get isLocal => source == NodeSource.localWork || source == NodeSource.localSingle;
  bool get isRemote => source == NodeSource.asmrServer || source == NodeSource.cloudDrive;

  bool get isAsmrServer => source == NodeSource.asmrServer;
  bool get isLocalWork => source == NodeSource.localWork;
  bool get isLocalSingle => source == NodeSource.localSingle;
  bool get isCloudDrive => source == NodeSource.cloudDrive;

  factory FileNode.fromJson(Map<String, dynamic> json) => _$FileNodeFromJson(json);
}