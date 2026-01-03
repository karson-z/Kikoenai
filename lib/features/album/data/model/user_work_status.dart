import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/enums/work_progress.dart';

/// 用户作品交互状态模型
@immutable
class UserWorkStatus {
  final int workId;
  final int rating;
  final String reviewText;
  final WorkProgress progress;

  const UserWorkStatus({
    required this.workId,
    this.rating = 0,
    this.reviewText = '',
    this.progress = WorkProgress.unknown,
  });

  // --- 1. CopyWith ---
  UserWorkStatus copyWith({
    int? workId,
    int? rating,
    String? reviewText,
    WorkProgress? progress,
  }) {
    return UserWorkStatus(
      workId: workId ?? this.workId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      progress: progress ?? this.progress,
    );
  }

  // --- 2. JSON 序列化 ---

  factory UserWorkStatus.fromMap(Map<String, dynamic> map) {
    return UserWorkStatus(
      workId: map['work_id']?.toInt() ?? 0,
      rating: map['rating']?.toInt() ?? 0,
      reviewText: map['review_text'] ?? '',
      progress: WorkProgress.fromString(map['progress']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'work_id': workId,
      'rating': rating,
      'review_text': reviewText,
      'progress': progress.toJson(),
    };
  }

  String toJson() => json.encode(toMap());

  factory UserWorkStatus.fromJson(String source) =>
      UserWorkStatus.fromMap(json.decode(source));

  // --- 3. 基础重写 ---

  @override
  String toString() {
    return 'UserWorkStatus(workId: $workId, rating: $rating, reviewText: $reviewText, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserWorkStatus &&
        other.workId == workId &&
        other.rating == rating &&
        other.reviewText == reviewText &&
        other.progress == progress;
  }

  @override
  int get hashCode {
    return Object.hash(workId, rating, reviewText, progress);
  }
}