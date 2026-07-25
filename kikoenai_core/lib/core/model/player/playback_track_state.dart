import 'package:flutter/foundation.dart'; // 用于 @immutable 注解

@immutable
class PlaybackTrackerState {
  final String? currentWorkId;      // 当前追踪的作品ID
  final int accumulatedSeconds;     // 累计播放秒数
  final bool hasReportedStart;      // 是否已上报开始
  final bool hasReported5Mins;      // 是否已上报5分钟
  final bool isPlaying;             // 是否正在播放

  const PlaybackTrackerState({
    this.currentWorkId,
    this.accumulatedSeconds = 0,
    this.hasReportedStart = false,
    this.hasReported5Mins = false,
    this.isPlaying = false,
  });

  PlaybackTrackerState copyWith({
    String? currentWorkId,
    int? accumulatedSeconds,
    bool? hasReportedStart,
    bool? hasReported5Mins,
    bool? isPlaying,
  }) {
    return PlaybackTrackerState(
      currentWorkId: currentWorkId ?? this.currentWorkId,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      hasReportedStart: hasReportedStart ?? this.hasReportedStart,
      hasReported5Mins: hasReported5Mins ?? this.hasReported5Mins,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaybackTrackerState &&
        other.currentWorkId == currentWorkId &&
        other.accumulatedSeconds == accumulatedSeconds &&
        other.hasReportedStart == hasReportedStart &&
        other.hasReported5Mins == hasReported5Mins &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentWorkId,
      accumulatedSeconds,
      hasReportedStart,
      hasReported5Mins,
      isPlaying,
    );
  }
  @override
  String toString() {
    return 'PlaybackTrackerState(currentWorkId: $currentWorkId, accumulatedSeconds: $accumulatedSeconds, hasReportedStart: $hasReportedStart, hasReported5Mins: $hasReported5Mins, isPlaying: $isPlaying)';
  }
}