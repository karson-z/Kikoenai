import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';
import 'package:kikoenai/features/album/data/model/circle.dart';
import 'package:kikoenai/features/album/data/model/other_language_edition.dart';
import 'package:kikoenai/features/album/data/model/rank.dart';
import 'package:kikoenai/features/album/data/model/rate_count_detail.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';

part 'work.freezed.dart';
part 'work.g.dart';

/// Work 主类
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

    /// Hero 动画唯一标识（不参与 JSON 与 Hive 持久化）
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? heroTag,
  }) = _Work;

  factory Work.fromJson(Map<String, dynamic> json) => _$WorkFromJson(json);

  /// 自动生成保证唯一的 HeroKey。
  ///
  /// 优先使用显式 [heroTag]；若为空，则基于 [id] 与当前实例的
  /// `identityHashCode` 组合生成稳定且实例级唯一的 tag。
  ///
  /// - 同一 [Work] 实例在源页面与目标页面（通过 `extra` 传递）读取到的 tag 一致，
  ///   保证 Hero 动画能正确连接。
  /// - 不同实例（即使 [id] 相同）会得到不同的 tag，避免在同一子树中出现
  ///   “多个 Hero 共享同一 tag”的冲突。
  String get effectiveHeroTag =>
      heroTag ?? 'work-$id-${identityHashCode(this)}';
}
