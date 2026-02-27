import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart'; // 或者 package:hive/hive.dart
import 'package:kikoenai/features/album/data/model/file_node.dart';
import 'package:kikoenai/features/player/data/model/progress_state.dart';

// 1. 添加 part 指令，文件名需与当前文件名一致 (例如 player_state.dart -> player_state.g.dart)
part 'player_state.g.dart';

// 2. 添加 HiveType 注解，typeId 保持为你之前的 3
@HiveType(typeId: 3)
class AppPlayerState {
  @HiveField(0)
  final bool playing;

  @HiveField(1)
  final bool loading;

  @HiveField(2)
  final ProgressBarState progressBarState; // 需确保 ProgressBarStateAdapter 已注册

  @HiveField(3)
  final MediaItem? currentTrack; // 需确保 MediaItemAdapter 已注册

  @HiveField(4)
  final List<MediaItem> playlist;

  @HiveField(5)
  final bool isFirst;

  @HiveField(6)
  final bool isLast;

  @HiveField(7)
  final bool shuffleEnabled;

  @HiveField(8)
  final AudioServiceRepeatMode repeatMode;

  @HiveField(9)
  final double volume;

  @HiveField(10)
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
    Map<String, FileNode?>? subtitleMapping,
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
      subtitleMapping: subtitleMapping ?? this.subtitleMapping,
    );
  }
}