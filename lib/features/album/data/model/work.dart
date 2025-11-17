import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:name_app/features/album/data/model/tag.dart';
import 'package:name_app/features/album/data/model/va.dart';
import 'audio_file.dart';


part 'work.g.dart';

@JsonSerializable()
class Work extends Equatable {
  final int id;
  final String title;

  @JsonKey(name: 'circle_id')
  final int? circleId;

  final String? name;
  final List<Va>? vas;
  final List<Tag>? tags;
  final String? age;
  final String? release;

  @JsonKey(name: 'dl_count')
  final int? dlCount;

  final int? price;

  @JsonKey(name: 'review_count')
  final int? reviewCount;

  @JsonKey(name: 'rate_count')
  final int? rateCount;

  @JsonKey(name: 'rate_average_2dp')
  final double? rateAverage;

  @JsonKey(name: 'has_subtitle')
  final bool? hasSubtitle;

  final int? duration;
  final String? progress;
  final List<String>? images;
  final String? description;
  final List<AudioFile>? children;

  const Work({
    required this.id,
    required this.title,
    this.circleId,
    this.name,
    this.vas,
    this.tags,
    this.age,
    this.release,
    this.dlCount,
    this.price,
    this.reviewCount,
    this.rateCount,
    this.rateAverage,
    this.hasSubtitle,
    this.duration,
    this.progress,
    this.images,
    this.description,
    this.children,
  });

  factory Work.fromJson(Map<String, dynamic> json) => _$WorkFromJson(json);
  Map<String, dynamic> toJson() => _$WorkToJson(this);

  String getCoverImageUrl(String baseUrl, {String? token}) {
    String normalizedUrl = baseUrl;
    if (baseUrl.isNotEmpty &&
        !baseUrl.startsWith('http://') &&
        !baseUrl.startsWith('https://')) {
      normalizedUrl = 'https://$baseUrl';
    }
    return token != null && token.isNotEmpty
        ? '$normalizedUrl/api/cover/$id?token=$token'
        : '$normalizedUrl/api/cover/$id';
  }

  String get circleTitle => name ?? '';

  @override
  List<Object?> get props => [
    id,
    title,
    circleId,
    name,
    vas,
    tags,
    age,
    release,
    dlCount,
    price,
    reviewCount,
    rateCount,
    rateAverage,
    hasSubtitle,
    duration,
    progress,
    images,
    description,
    children,
  ];
}
