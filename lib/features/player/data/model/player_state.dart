import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'package:kikoenai/features/player/data/model/progress_state.dart';

class AppPlayerState {
  final bool playing;
  final bool loading;
  final ProgressBarState progressBarState;
  final MediaItem? currentTrack;
  final List<MediaItem> playlist;
  final bool isFirst;
  final bool isLast;
  final bool shuffleEnabled;
  final AudioServiceRepeatMode repeatMode;
  final double volume;
  final List<FileNode> subtitleList; // 待匹配字幕列表
  // 匹配关系表: Key是音频ID (MediaItem.id), Value是字幕文件 (FileNode)
  final Map<String, FileNode?> subtitleMapping;
  FileNode? get currentSubtitle =>
      currentTrack != null ? subtitleMapping[currentTrack!.id] : null;
  // ----------------

  AppPlayerState({
    this.playing = false,
    this.loading = false,
    ProgressBarState? progressBarState,
    this.currentTrack,
    this.playlist = const [],
    this.isFirst = true,
    this.isLast = true,
    this.shuffleEnabled = false,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.volume = 1.0,
    this.subtitleList = const [],
    this.subtitleMapping = const {},
  }) : progressBarState = progressBarState ??
      const ProgressBarState(
        current: Duration.zero,
        buffered: Duration.zero,
        total: Duration.zero,
      );

  AppPlayerState copyWith({
    bool? playing,
    bool? loading,
    ProgressBarState? progressBarState,
    MediaItem? currentTrack,
    List<MediaItem>? playlist,
    bool? isFirst,
    bool? isLast,
    bool? shuffleEnabled,
    AudioServiceRepeatMode? repeatMode,
    double? volume,
    List<FileNode>? subtitleList,
    Map<String, FileNode?>? subtitleMapping,
    // --------------------
  }) {
    return AppPlayerState(
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      progressBarState: progressBarState ?? this.progressBarState,
      currentTrack: currentTrack ?? this.currentTrack,
      playlist: playlist ?? this.playlist,
      isFirst: isFirst ?? this.isFirst,
      isLast: isLast ?? this.isLast,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      subtitleList: subtitleList ?? this.subtitleList,
      subtitleMapping: subtitleMapping ?? this.subtitleMapping,
    );
  }
}