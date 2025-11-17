// import 'package:name_app/core/enums/age_rating.dart';
// import 'package:name_app/features/author/data/model/author.dart';
// import 'package:name_app/features/circle/data/model/circle_vo.dart';
// import 'package:name_app/features/tag/data/model/tag_vo.dart';
//
// class AlbumResponse {
//   final int? id;
//   final String? albumTitle;
//   final String? rjCode;
//   final AgeRatingEnum? ageRating;
//   final CircleVo? circleVo;
//   final String? coverUrl;
//   final List<TagVo>? tags;
//   final List<Author>? authorId;
//   final DateTime? createdAt;
//
//   AlbumResponse({
//     this.id,
//     this.albumTitle,
//     this.rjCode,
//     this.ageRating,
//     this.circleVo,
//     this.coverUrl,
//     this.tags,
//     this.authorId,
//     this.createdAt,
//   });
//
//   factory AlbumResponse.fromJson(Map<String, dynamic> json) {
//     return AlbumResponse(
//       id: json['id'] as int?,
//       albumTitle: json['albumTitle'] as String?,
//       rjCode: json['rjCode'] as String?,
//       ageRating: json['ageRating'] != null
//           ? AgeRatingEnum.fromValue(json['ageRating'])
//           : null,
//       circleVo:
//           json['circleVo'] != null ? CircleVo.fromJson(json['circleVo']) : null,
//       coverUrl: json['coverUrl'] as String?,
//       tags: (json['tags'] as List?)
//           ?.map((e) => TagVo.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       authorId: (json['authorId'] as List?)
//           ?.map((e) => Author.fromJson(e as Map<String, dynamic>))
//           .toList(),
//       createdAt: json['createdAt'] != null
//           ? DateTime.tryParse(json['createdAt'])
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'albumTitle': albumTitle,
//       'rjCode': rjCode,
//       'ageRating': ageRating?.value,
//       'circleVo': circleVo?.toJson(),
//       'coverUrl': coverUrl,
//       'tags': tags?.map((e) => e.toJson()).toList(),
//       'authorId': authorId?.map((e) => e.toJson()).toList(),
//       'createdAt': createdAt?.toIso8601String(),
//     };
//   }
//
//   @override
//   String toString() => 'AlbumResponse(id: $id, title: $albumTitle)';
// }
