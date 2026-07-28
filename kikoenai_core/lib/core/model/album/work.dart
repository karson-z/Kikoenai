import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/core/model/album/circle.dart';
import 'package:kikoenai_core/core/model/album/other_language_edition.dart';
import 'package:kikoenai_core/core/model/album/rank.dart';
import 'package:kikoenai_core/core/model/album/rate_count_detail.dart';
import 'package:kikoenai_core/core/model/album/tag.dart';
import 'package:kikoenai_core/core/model/album/va.dart';
import 'package:kikoenai_core/core/constants/type_ids.dart';
import 'package:kikoenai_core/core/model/site/site_content_id.dart';

part 'work.freezed.dart';
part 'work.g.dart';

/// Work main model
@freezed
@HiveType(typeId: TypeIds.work, adapterName: 'WorkAdapter')
abstract class Work with _$Work {
  const Work._();

  const factory Work({
    @HiveField(0) required int id,
    @HiveField(1) String? title,
    @HiveField(2) @JsonKey(name: 'circle_id') int? circleId,
    @HiveField(3) String? name,
    @HiveField(4) bool? nsfw,
    @HiveField(5) String? release,
    @HiveField(6) @JsonKey(name: 'dl_count') int? dlCount,
    @HiveField(7) int? price,
    @HiveField(8) @JsonKey(name: 'review_count') int? reviewCount,
    @HiveField(9) @JsonKey(name: 'review_text') String? reviewText,
    @HiveField(10) @JsonKey(name: 'rate_count') int? rateCount,
    @HiveField(11) @JsonKey(name: 'rate_average_2dp') double? rateAverage2dp,
    @HiveField(12)
    @JsonKey(name: 'rate_count_detail')
    List<RateCountDetail>? rateCountDetail,
    @HiveField(13) List<Rank>? rank,
    @HiveField(14) @JsonKey(name: 'has_subtitle') bool? hasSubtitle,
    @HiveField(15) @JsonKey(name: 'create_date') String? createDate,
    @HiveField(16) List<VA>? vas,
    @HiveField(17) List<Tag>? tags,
    @HiveField(18) @JsonKey(name: 'original_workno') String? originalWorkno,
    @HiveField(19)
    @JsonKey(name: 'other_language_editions_in_db')
    List<OtherLanguageEdition>? otherLanguageEditionsInDb,
    @HiveField(20) @JsonKey(name: 'work_attributes') String? workAttributes,
    @HiveField(21)
    @JsonKey(name: 'age_category_string')
    String? ageCategoryString,
    @HiveField(22) int? duration,
    @HiveField(23) @JsonKey(name: 'source_type') String? sourceType,
    @HiveField(24) @JsonKey(name: 'source_id') String? sourceId,
    @HiveField(25) @JsonKey(name: 'source_url') String? sourceUrl,
    @HiveField(26) @JsonKey(name: 'updated_at') String? updatedAt,
    @HiveField(27) dynamic userRating,
    @HiveField(28) Map<String, bool>? playlistStatus,
    @HiveField(29) Circle? circle,
    @HiveField(30) String? samCoverUrl,
    @HiveField(31) String? thumbnailCoverUrl,
    @HiveField(32) String? mainCoverUrl,
    @HiveField(33) String? progress,

    /// Origin site and its native string identifier.
    @HiveField(34) String? siteId,
    @HiveField(35) String? remoteId,

    /// Hero animation unique identifier (excluded from JSON and Hive persistence)
    @JsonKey(includeFromJson: false, includeToJson: false) String? heroTag,
  }) = _Work;

  factory Work.fromJson(Map<String, dynamic> json) => _$WorkFromJson(json);

  /// Auto-generated unique HeroKey tag.
  ///
  /// Prefers the explicit [heroTag]; if empty, builds a stable and instance-unique
  /// tag based on [id] and the current instance's `identityHashCode`.
  SiteContentId get contentId => SiteContentId(
    siteId: siteId ?? SiteContentId.legacySiteId,
    remoteId: remoteId ?? id.toString(),
  );

  String get effectiveHeroTag =>
      heroTag ?? 'work-${contentId.storageKey}-${identityHashCode(this)}';
}
