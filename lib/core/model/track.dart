import 'package:flutter/foundation.dart';

import '../../features/album/data/model/work_info.dart';

@immutable
class Track {
  final String title;
  final String workTitle;
  final WorkInfo work;
  final String mediaDownloadUrl;
  final String mediaStreamUrl;
  final String streamLowQualityUrl;
  final double duration; // 秒

  const Track({
    required this.title,
    required this.workTitle,
    required this.work,
    required this.mediaDownloadUrl,
    required this.mediaStreamUrl,
    required this.streamLowQualityUrl,
    required this.duration,
  });

  // ---------- copyWith ----------
  Track copyWith({
    String? title,
    String? workTitle,
    WorkInfo? work,
    String? mediaDownloadUrl,
    String? mediaStreamUrl,
    String? streamLowQualityUrl,
    double? duration,
  }) {
    return Track(
      title: title ?? this.title,
      workTitle: workTitle ?? this.workTitle,
      work: work ?? this.work,
      mediaDownloadUrl: mediaDownloadUrl ?? this.mediaDownloadUrl,
      mediaStreamUrl: mediaStreamUrl ?? this.mediaStreamUrl,
      streamLowQualityUrl: streamLowQualityUrl ?? this.streamLowQualityUrl,
      duration: duration ?? this.duration,
    );
  }

  // ---------- fromJson ----------
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      title: json['title'] ?? '',
      workTitle: json['workTitle'] ?? '',
      work: json['work'] != null
          ? WorkInfo.fromJson(json['work'] as Map<String, dynamic>)
          : const WorkInfo(id: 0), // 给个兜底，避免 null
      mediaDownloadUrl: json['mediaDownloadUrl'] ?? '',
      mediaStreamUrl: json['mediaStreamUrl'] ?? '',
      streamLowQualityUrl: json['streamLowQualityUrl'] ?? '',
      duration: (json['duration'] is int)
          ? (json['duration'] as int).toDouble()
          : (json['duration'] ?? 0.0).toDouble(),
    );
  }

  // ---------- toJson ----------
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'workTitle': workTitle,
      'work': work.toJson(),
      'mediaDownloadUrl': mediaDownloadUrl,
      'mediaStreamUrl': mediaStreamUrl,
      'streamLowQualityUrl': streamLowQualityUrl,
      'duration': duration,
    };
  }

  // ---------- equality ----------
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Track &&
            other.title == title &&
            other.workTitle == workTitle &&
            other.work == work &&
            other.mediaDownloadUrl == mediaDownloadUrl &&
            other.mediaStreamUrl == mediaStreamUrl &&
            other.streamLowQualityUrl == streamLowQualityUrl &&
            other.duration == duration);
  }

  @override
  int get hashCode => Object.hash(
    title,
    workTitle,
    work,
    mediaDownloadUrl,
    mediaStreamUrl,
    streamLowQualityUrl,
    duration,
  );

  @override
  String toString() =>
      'Track(title: $title, workTitle: $workTitle, work: $work, duration: $duration)';
}
