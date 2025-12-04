import '../../features/album/data/model/work.dart';
import '../widgets/player/state/player_state.dart';

class HistoryEntry {
  final Work work;
  final int updatedAt; // 最后播放时间戳
  final String? lastTrackId; // 当前播放的曲目 ID
  final String? currentTrackTitle; // 曲目标题
  final int? lastProgressMs; // 播放进度（毫秒）

  const HistoryEntry({
    required this.work,
    required this.updatedAt,
    this.lastTrackId,
    this.currentTrackTitle,
    this.lastProgressMs,
  });

  HistoryEntry copyWith({
    Work? work,
    int? updatedAt,
    String? lastTrackId,
    String? currentTrackTitle,
    int? lastProgressMs,
  }) {
    return HistoryEntry(
      work: work ?? this.work,
      updatedAt: updatedAt ?? this.updatedAt,
      lastTrackId: lastTrackId ?? this.lastTrackId,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      lastProgressMs: lastProgressMs ?? this.lastProgressMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'work': work.toJson(),
      'updatedAt': updatedAt,
      'lastTrackId': lastTrackId,
      'currentTrackTitle': currentTrackTitle,
      'lastProgressMs': lastProgressMs,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      work: Work.fromJson(map['work']),
      updatedAt: map['updatedAt'],
      lastTrackId: map['lastTrackId'],
      currentTrackTitle: map['currentTrackTitle'],
      lastProgressMs: map['lastProgressMs'],
    );
  }
}
