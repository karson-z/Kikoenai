import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/player/data/model/progress_state.dart';
import 'package:media_kit/media_kit.dart';

import '../../../../core/constants/app_typeIds.dart';

part 'player_state.freezed.dart';
part 'player_state.g.dart';

@freezed
@HiveType(typeId: TypeIds.appPlayerState, adapterName: 'AppPlayerStateAdapter')
abstract class AppPlayerState with _$AppPlayerState {
  const AppPlayerState._();

  const factory AppPlayerState({
    @HiveField(0) @Default(false) bool playing,
    @HiveField(1) @Default(false) bool loading,
    @HiveField(2)
    @Default(ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ))
    ProgressBarState progressBarState,
    @HiveField(3) MediaItem? currentTrack,
    @HiveField(4) @Default([]) List<MediaItem> playlist,
    @HiveField(5) @Default(true) bool isFirst,
    @HiveField(6) @Default(true) bool isLast,
    @HiveField(7) @Default(false) bool shuffleEnabled,
    @HiveField(8) @Default(AudioServiceRepeatMode.none) AudioServiceRepeatMode repeatMode,
    @HiveField(9) @Default(1.0) double volume,
    @HiveField(10) @Default({}) Map<String, FileNode?> subtitleMapping,
    @HiveField(11) @Default([]) List<FileNode?> lyricsList,
    @HiveField(12) @Default(false) bool isAudioOnly,
    @Default(true) bool isVideoControlsVisible,
    @Default(0) int videoWidth,
    @Default(0) int videoHeight,
    @Default(0) int videoRotate,
    @Default('') String audioParams,
    AudioTrack? audioTrack,
    SubtitleTrack? subtitleTrack,
    @Default([]) List<AudioTrack> availableAudioTracks,
    @Default([]) List<SubtitleTrack> availableSubtitleTracks,
    // 外部挂载的轨道列表
    @Default([]) List<AudioTrack> externalAudioTracks,
    @Default([]) List<SubtitleTrack> externalSubtitleTracks,
  }) = _AppPlayerState;

  FileNode? get currentSubtitle =>
      currentTrack != null ? subtitleMapping[currentTrack!.id] : null;

  bool get isVideoPortrait {
    if (videoWidth == 0 || videoHeight == 0) return false;
    final isRotatedSideWays = videoRotate == 90 || videoRotate == 270;
    final effectiveWidth = isRotatedSideWays ? videoHeight : videoWidth;
    final effectiveHeight = isRotatedSideWays ? videoWidth : videoHeight;
    return effectiveHeight > effectiveWidth;
  }

  List<SubtitleTrack> get allSubtitleTracks =>
      [...availableSubtitleTracks, ...externalSubtitleTracks];

  List<AudioTrack> get allAudioTracks =>
      [...availableAudioTracks, ...externalAudioTracks];

  // 当前是否是视频播放页面
  bool get isCurrentVideoView {
    if (currentTrack == null) return false;
    // 当视频宽高都大于0 且 !isAudioOnly 的时候必然是视频
    return videoWidth > 0 && videoHeight > 0 && !isAudioOnly;
  }
}