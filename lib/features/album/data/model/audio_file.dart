import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'audio_file.g.dart';

@JsonSerializable()
class AudioFile extends Equatable {
  final String title;
  final String? type;
  final String? hash;
  final List<AudioFile>? children;

  @JsonKey(name: 'mediaDownloadUrl')
  final String? mediaDownloadUrl;

  final int? size;

  const AudioFile({
    required this.title,
    this.type,
    this.hash,
    this.children,
    this.mediaDownloadUrl,
    this.size,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) =>
      _$AudioFileFromJson(json);

  Map<String, dynamic> toJson() => _$AudioFileToJson(this);

  bool get isFolder => type == 'folder';
  bool get isAudio => type == 'audio';
  bool get isText => type == 'text';
  bool get isImage => type == 'image';

  @override
  List<Object?> get props =>
      [title, type, hash, children, mediaDownloadUrl, size];
}
