import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/player/data/model/progress_state.dart';

import '../../../../core/constants/app_typeIds.dart';

part 'player_state.g.dart';

@HiveType(typeId: TypeIds.appPlayerState)
class AppPlayerState {
  @HiveField(0)
  final bool playing;

  @HiveField(1)
  final bool loading;

  @HiveField(2)
  final ProgressBarState progressBarState;

  @HiveField(3)
  final MediaItem? currentTrack;

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

  @HiveField(11)
  final List<FileNode?> lyricsList;

  FileNode? get currentSubtitle =>
      currentTrack != null ? subtitleMapping[currentTrack!.id] : null;


  AppPlayerState({
    this.playing = false,
    this.loading = false,
    ProgressBarState? progressBarState,
    this.currentTrack,
    this.lyricsList = const [],
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
    List<FileNode>? lyricsList,
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
      lyricsList: lyricsList ?? this.lyricsList,
      isFirst: isFirst ?? this.isFirst,
      isLast: isLast ?? this.isLast,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      subtitleMapping: subtitleMapping ?? this.subtitleMapping,
    );
  }
}