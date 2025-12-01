// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rank _$RankFromJson(Map<String, dynamic> json) => Rank(
      term: json['term'] as String,
      category: json['category'] as String,
      rank: (json['rank'] as num).toInt(),
      rankDate: json['rank_date'] as String,
    );

Map<String, dynamic> _$RankToJson(Rank instance) => <String, dynamic>{
      'term': instance.term,
      'category': instance.category,
      'rank': instance.rank,
      'rank_date': instance.rankDate,
    };
