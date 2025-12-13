import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/widgets/player/state/progress_state.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart'; // 假设你用了这个包

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

  // --- 新增状态 ---
  final List<FileNode> subtitleList; // 字幕列表 (例如文件路径列表)
  final FileNode? currentSubtitle;   // 当前选中的字幕 (可能为空)
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
    // --- 初始化新增状态 ---
    this.subtitleList = const [],
    this.currentSubtitle,
    // --------------------
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
    FileNode? currentSubtitle,
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
      currentSubtitle: currentSubtitle ?? this.currentSubtitle,
    );
  }
}