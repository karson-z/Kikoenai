
import 'package:json_annotation/json_annotation.dart';

part 'translation_status.g.dart';

@JsonSerializable()
class TranslationStatus {
  @JsonKey(name: 'is_denied')
  final bool isDenied;
  @JsonKey(name: 'bonus_price')
  final int bonusPrice;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'applied_count')
  final int appliedCount;
  @JsonKey(name: 'on_sale_count')
  final int onSaleCount;

  TranslationStatus({
    required this.isDenied,
    required this.bonusPrice,
    required this.isAvailable,
    required this.appliedCount,
    required this.onSaleCount,
  });

  factory TranslationStatus.fromJson(Map<String, dynamic> json) =>
      _$TranslationStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationStatusToJson(this);
}
