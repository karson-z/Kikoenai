// player_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// player_state.dart
import 'package:flutter/material.dart';
import 'package:name_app/core/model/track.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

/// 使用标准 Dart 类实现不可变状态模型
import 'package:flutter/foundation.dart';

@immutable
class PlayerState {
  final bool isPlaying;

  /// 当前播放的音乐（Track）
  final Track? currentTrack;

  /// 当前播放的作品（Work）
  final Work? currentWork;

  /// 当前播放列表
  final List<Track>? playlist;

  /// 进度百分比（0–100）
  final double currentProgress;

  /// 音量百分比（0–100）
  final double currentVolume;

  /// 模式：是否开启循环(暂时没定枚举)
  final bool isRepeatEnabled;

  /// 播放列表是否打开
  final bool isQueueOpen;

  const PlayerState({
    this.isPlaying = false,
    this.currentWork,
    this.currentTrack,
    this.playlist,
    this.currentProgress = 0,
    this.currentVolume = 70,
    this.isRepeatEnabled = false,
    this.isQueueOpen = false,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Track? currentTrack,
    List<Track>? playlist,
    Work? currentWork,
    double? currentProgress,
    double? currentVolume,
    bool? isRepeatEnabled,
    bool? isQueueOpen,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      currentWork: currentWork ?? this.currentWork,
      playlist: playlist ?? this.playlist,
      currentProgress: currentProgress ?? this.currentProgress,
      currentVolume: currentVolume ?? this.currentVolume,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      isQueueOpen: isQueueOpen ?? this.isQueueOpen,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlayerState &&
            other.isPlaying == isPlaying &&
            other.currentTrack == currentTrack &&
            other.playlist == playlist &&
            other.currentWork == currentWork &&
            other.currentProgress == currentProgress &&
            other.currentVolume == currentVolume &&
            other.isRepeatEnabled == isRepeatEnabled &&
            other.isQueueOpen == isQueueOpen;
  }

  @override
  int get hashCode => Object.hash(
    currentWork,
    playlist,
    isPlaying,
    currentTrack,
    currentProgress,
    currentVolume,
    isRepeatEnabled,
    isQueueOpen,
  );
}


// 🎯 PlayerNotifier 负责所有业务逻辑和状态更新
class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    // 使用你的 PlayerState 默认构造即可
    return const PlayerState();
  }

  /// 播放/暂停
  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
    print("播放状态切换: ${state.isPlaying}");
  }

  void setPlaylist(List<Track> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) return;

    // 边界处理
    final index = startIndex.clamp(0, tracks.length - 1);

    state = state.copyWith(
      playlist: List.unmodifiable(tracks),
      currentTrack: tracks[index],
      isPlaying: true, // 一般设置列表就开始播放
    );

    print("播放列表已设置，共 ${tracks
        .length} 首，从第 $index 首开始：${tracks[index].title}");
  }

  void setCurrentTrack(Track track) {
    final currentList = state.playlist;

    // 如果没有播放列表，默认放进去
    if (currentList == null || currentList.isEmpty) {
      state = state.copyWith(
        playlist: [track],
        currentTrack: track,
        isPlaying: true,
      );
    } else {
      state = state.copyWith(
        currentTrack: track,
        isPlaying: true,
      );
    }
  }
    /// 上一首
    void skipPrevious() {
      print("跳到上一首");
      // TODO: 调用你的音乐后台逻辑
    }

    /// 下一首
    void skipNext() {
      print("跳到下一首");
      // TODO: 调用你的音乐后台逻辑
    }

    /// 拖动进度条（0–100）
    void seek(double newProgress) {
      state = state.copyWith(currentProgress: newProgress);
      print("进度条拖动到: $newProgress");
    }

    /// 调整音量（0–100）
    void changeVolume(double newVolume) {
      state = state.copyWith(currentVolume: newVolume);
      print("音量调整到: $newVolume");
    }

    /// 切换循环模式
    void toggleRepeat() {
      state = state.copyWith(isRepeatEnabled: !state.isRepeatEnabled);
      print("循环模式切换: ${state.isRepeatEnabled}");
    }

    /// 打开或关闭播放列表
    void toggleQueue(PanelController controller) {
      controller.open();
    }

    /// 收起播放器 UI（不操作状态）
    void minimizePlayer() {
      print("收起播放器");
    }

    /// 更多选项
    void showMoreOptions() {
      print("显示更多选项");
    }

}

// ---------------------------------------------------------------
//                       Provider
// ---------------------------------------------------------------

final playerNotifierProvider = NotifierProvider<PlayerNotifier, PlayerState>(() => PlayerNotifier());