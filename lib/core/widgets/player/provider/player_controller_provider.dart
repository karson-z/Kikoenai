import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';

import '../../../service/audio_service.dart';

class PlayerState {
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration buffered;
  final Duration total;
  final MediaItem? currentTrack;
  final List<MediaItem> playlist;
  final bool isFirst;
  final bool isLast;
  final bool shuffleEnabled;
  final AudioServiceRepeatMode repeatMode;
  final double volume;

  PlayerState({
    required this.playing,
    required this.loading,
    required this.position,
    required this.buffered,
    required this.total,
    this.currentTrack,
    required this.playlist,
    required this.isFirst,
    required this.isLast,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.volume,
  });

  PlayerState copyWith({
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? buffered,
    Duration? total,
    MediaItem? currentTrack,
    List<MediaItem>? playlist,
    bool? isFirst,
    bool? isLast,
    bool? shuffleEnabled,
    AudioServiceRepeatMode? repeatMode,
    double? volume,
  }) {
    return PlayerState(
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      total: total ?? this.total,
      currentTrack: currentTrack ?? this.currentTrack,
      playlist: playlist ?? this.playlist,
      isFirst: isFirst ?? this.isFirst,
      isLast: isLast ?? this.isLast,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
    );
  }

  factory PlayerState.initial() {
    return PlayerState(
      playing: false,
      loading: false,
      position: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
      currentTrack: null,
      playlist: const [],
      isFirst: true,
      isLast: true,
      shuffleEnabled: false,
      repeatMode: AudioServiceRepeatMode.none,
      volume: 1.0,
    );
  }
}

final playerControllerProvider = NotifierProvider<PlayerController, PlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<PlayerState> {
  late final AudioHandler handler;

  @override
  PlayerState build() {
    handler = ref.read(audioHandlerFutureProvider);
    _listen();
    return PlayerState.initial();
  }


  void _listen() {
    handler.playbackState.listen((p) {
      state = state.copyWith(
        playing: p.playing,
        loading: p.processingState == AudioProcessingState.loading ||
            p.processingState == AudioProcessingState.buffering,
        buffered: p.bufferedPosition,
      );
    });
    handler.mediaItem.listen((item) {
      state = state.copyWith(
        currentTrack: item
      );
      _updateSkipInfo();
    });

    handler.queue.listen((queue) {
      state = state.copyWith(playlist: queue);
      _updateSkipInfo();
    });

    AudioService.position.listen((pos) {
      state = state.copyWith(position: pos);
    });

    // 若使用自定义音量
    if (handler is MyAudioHandler) {
      final h = handler as MyAudioHandler;
      h.volumeStream.listen((v) {
        state = state.copyWith(volume: v);
      });
    }
  }

  void _updateSkipInfo() {
    final playlist = state.playlist;
    final current = handler.mediaItem.value;

    if (playlist.isEmpty || current == null) {
      state = state.copyWith(isFirst: true, isLast: true);
      return;
    }

    final i = playlist.indexOf(current);
    state = state.copyWith(
      isFirst: i <= 0,
      isLast: i >= playlist.length - 1,
    );
  }

  // --- 控制方法 ---

  Future<void> play() async {
    final title = handler.mediaItem.value?.title;
    debugPrint('title: $title');
    handler.play();
  }
  Future<void> pause() => handler.pause();

  Future<void> stop() => handler.stop();

  Future<void> seek(Duration d) => handler.seek(d);

  Future<void> next() => handler.skipToNext();

  Future<void> previous() => handler.skipToPrevious();

  Future<void> setVolume(double v) async {
    if (handler is MyAudioHandler) {
      await (handler as MyAudioHandler).setVolume(v);
    }
  }

  Future<void> toggleShuffle() async {
    final enabled = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: enabled);
    await handler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  Future<void> setRepeat(AudioServiceRepeatMode mode) async {
    state = state.copyWith(repeatMode: mode);
    await handler.setRepeatMode(mode);
  }

  Future<void> add(MediaItem item) => handler.addQueueItem(item);

  Future<void> addAll(List<MediaItem> items) => handler.addQueueItems(items);

  Future<void> skipTo(int index) => handler.skipToQueueItem(index);

  Future<void> clear() => (handler as MyAudioHandler).clearPlaylist() ;

}
