import 'package:json_annotation/json_annotation.dart';
import 'package:name_app/features/album/data/model/language_edition.dart';
import 'package:name_app/features/album/data/model/rank.dart';
import 'package:name_app/features/album/data/model/rate_count_detail.dart';
import 'package:name_app/features/album/data/model/tag.dart';
import 'package:name_app/features/album/data/model/translation_info.dart';
import 'package:name_app/features/album/data/model/va.dart';

import 'circle.dart';
import 'other_language_edition.dart';

part 'work.g.dart';

/// Work 主类
@JsonSerializable(explicitToJson: true)
class Work{
  final int? id;
  final String? title;
  @JsonKey(name: 'circle_id')
  final int? circleId;
  final String? name;
  final bool? nsfw;
  final String? release;
  @JsonKey(name: 'dl_count')
  final int? dlCount;
  final int? price;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  @JsonKey(name: 'rate_count')
  final int? rateCount;
  @JsonKey(name: 'rate_average_2dp')
  final int? rateAverage2dp;
  @JsonKey(name: 'rate_count_detail')
  final List<RateCountDetail>? rateCountDetail;
  final List<Rank>? rank;
  @JsonKey(name: 'has_subtitle')
  final bool? hasSubtitle;
  @JsonKey(name: 'create_date')
  final String? createDate;
  final List<VA>? vas;
  final List<Tag>? tags;
  @JsonKey(name: 'language_editions')
  final List<LanguageEdition>? languageEditions;
  @JsonKey(name: 'original_workno')
  final String? originalWorkno;
  @JsonKey(name: 'other_language_editions_in_db')
  final List<OtherLanguageEdition>? otherLanguageEditionsInDb;
  @JsonKey(name: 'work_attributes')
  final String? workAttributes;
  @JsonKey(name: 'age_category_string')
  final String? ageCategoryString;
  final int? duration;
  @JsonKey(name: 'source_type')
  final String? sourceType;
  @JsonKey(name: 'source_id')
  final String? sourceId;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  final dynamic userRating;
  final Circle? circle;
  final String? samCoverUrl;
  final String? thumbnailCoverUrl;
  final String? mainCoverUrl;

  Work({
    this.id,
    this.title,
    this.circleId,
    this.name,
    this.nsfw,
    this.release,
    this.dlCount,
    this.price,
    this.reviewCount,
    this.rateCount,
    this.rateAverage2dp,
    this.rateCountDetail,
    this.rank,
    this.hasSubtitle,
    this.createDate,
    this.vas,
    this.tags,
    this.languageEditions,
    this.originalWorkno,
    this.otherLanguageEditionsInDb,
    this.workAttributes,
    this.ageCategoryString,
    this.duration,
    this.sourceType,
    this.sourceId,
    this.sourceUrl,
    this.userRating,
    this.circle,
    this.samCoverUrl,
    this.thumbnailCoverUrl,
    this.mainCoverUrl,
  });

  factory Work.fromJson(Map<String, dynamic> json) => _$WorkFromJson(json);
  Map<String, dynamic> toJson() => _$WorkToJson(this);

  Work copyWith({
    int? id,
    String? title,
    int? circleId,
    String? name,
    bool? nsfw,
    String? release,
    int? dlCount,
    int? price,
    int? reviewCount,
    int? rateCount,
    int? rateAverage2dp,
    List<RateCountDetail>? rateCountDetail,
    List<Rank>? rank,
    bool? hasSubtitle,
    String? createDate,
    List<VA>? vas,
    List<Tag>? tags,
    List<LanguageEdition>? languageEditions,
    String? originalWorkno,
    List<OtherLanguageEdition>? otherLanguageEditionsInDb,
    TranslationInfo? translationInfo,
    String? workAttributes,
    String? ageCategoryString,
    int? duration,
    String? sourceType,
    String? sourceId,
    String? sourceUrl,
    dynamic userRating,
    Circle? circle,
    String? samCoverUrl,
    String? thumbnailCoverUrl,
    String? mainCoverUrl,
  }) {
    return Work(
      id: id ?? this.id,
      title: title ?? this.title,
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      nsfw: nsfw ?? this.nsfw,
      release: release ?? this.release,
      dlCount: dlCount ?? this.dlCount,
      price: price ?? this.price,
      reviewCount: reviewCount ?? this.reviewCount,
      rateCount: rateCount ?? this.rateCount,
      rateAverage2dp: rateAverage2dp ?? this.rateAverage2dp,
      rateCountDetail: rateCountDetail ?? this.rateCountDetail,
      rank: rank ?? this.rank,
      hasSubtitle: hasSubtitle ?? this.hasSubtitle,
      createDate: createDate ?? this.createDate,
      vas: vas ?? this.vas,
      tags: tags ?? this.tags,
      languageEditions: languageEditions ?? this.languageEditions,
      originalWorkno: originalWorkno ?? this.originalWorkno,
      otherLanguageEditionsInDb: otherLanguageEditionsInDb ?? this.otherLanguageEditionsInDb,
      workAttributes: workAttributes ?? this.workAttributes,
      ageCategoryString: ageCategoryString ?? this.ageCategoryString,
      duration: duration ?? this.duration,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      userRating: userRating ?? this.userRating,
      circle: circle ?? this.circle,
      samCoverUrl: samCoverUrl ?? this.samCoverUrl,
      thumbnailCoverUrl: thumbnailCoverUrl ?? this.thumbnailCoverUrl,
      mainCoverUrl: mainCoverUrl ?? this.mainCoverUrl,
    );
  }

  @override
  String toString() {
    return 'Work(id: $id, title: $title, circleId: $circleId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Work &&
        other.id == id &&
        other.title == title &&
        other.circleId == circleId &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, title, circleId, name);
}
