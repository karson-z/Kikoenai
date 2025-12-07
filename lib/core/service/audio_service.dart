import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioServiceSingleton {
  AudioServiceSingleton._();
  static late final AudioHandler _instance;

  static AudioHandler get instance {
    return _instance;
  }

  static Future<void> init() async {
    debugPrint("AudioServiceSingleton.init()");
    _instance = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.karson.kikoenai.audio',
        androidNotificationChannelName: 'Kikoenai',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
      ),
    );
  }
}

final audioHandlerFutureProvider = Provider<AudioHandler>((ref) {
  return AudioServiceSingleton.instance;
});

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  // 自己维护的播放列表
  final List<MediaItem> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaylistPrepared = false;

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPlaybackCompletion();
    _listenForPositionChanges();
  }
  int get currentIndex => _currentIndex;

  Future<void> setCurrentIndex(int index) async {
    _currentIndex = index;
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      return;
    }

    final newMediaItem = _playlist[_currentIndex];
    final url = newMediaItem.extras!['url'] as String;
    // 手动改变当前播放的歌曲
    mediaItem.add(newMediaItem);
    playbackState.add(playbackState.value.copyWith(
      queueIndex: _currentIndex,
      playing: false,
      processingState: AudioProcessingState.loading, // 标记加载中
    ));
    try {
      // 设置当前播放音频URI 如果设置多个播放列表，桌面端无法兼容；
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  // 播放
  Stream<double> get volumeStream => _player.volumeStream;
  double get volume => _player.volume;
  Future<void> setVolume(double v) => _player.setVolume(v);

  // 播放当前索引的歌曲
  Future<void> _playCurrentIndex() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      return;
    }

    final newMediaItem = _playlist[_currentIndex];
    final url = newMediaItem.extras!['url'] as String;
    // 手动改变当前播放的歌曲
    mediaItem.add(newMediaItem);
    playbackState.add(playbackState.value.copyWith(
      queueIndex: _currentIndex,
      playing: false,
      processingState: AudioProcessingState.loading, // 标记加载中
    ));
    try {
      // 设置当前播放音频URI 如果设置多个播放列表，桌面端无法兼容；
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      playbackState.add(playbackState.value.copyWith(
        queueIndex: _currentIndex,
      ));
      await _player.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      // 更新 AudioService 播放状态
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: AudioServiceShuffleMode.none,
        playing: playing,
        // updatePosition: _player.position,
        // bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });
  }
  void _listenForPositionChanges() {
    // just_audio 提供了一个专门用于播放进度监听的流，需要单独进行更新，而不是加入到播放事件流监听中进行更新
    // 由于安卓和windows底层使用的播放器不同，playbackEventStream 在移动端被操作系统节流变成每隔3秒更新一次
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _player.bufferedPositionStream.listen((bufferedPosition) {
      playbackState.add(playbackState.value.copyWith(
        bufferedPosition: bufferedPosition,
      ));
    });
  }
  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        final oldMediaItem = _playlist[_currentIndex];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        _playlist[_currentIndex] = newMediaItem;
        queue.add(_playlist);
        mediaItem.add(newMediaItem);
      }
    });
  }
  bool _alreadyCompleted = false;
  void _listenForPlaybackCompletion() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_alreadyCompleted) return;  // 第二次 completed 会被直接忽略
        _alreadyCompleted = true;

        print("播放完成 → 跳下一首");
        _skipToNext();
      }

      // 当播放开始、缓冲、ready 时重置
      if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading) {
        _alreadyCompleted = false;
      }
    });
  }
  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    // 记录当前播放歌曲
    MediaItem? current = (_currentIndex >= 0 && _currentIndex < _playlist.length)
        ? _playlist[_currentIndex]
        : null;

    // 替换播放列表
    _playlist
      ..clear()
      ..addAll(queue);

    // 重新计算当前歌曲的索引
    if (current != null) {
      final newIndex = _playlist.indexWhere((it) => it.id == current.id);

      if (newIndex != -1) {
        _currentIndex = newIndex;
      } else {
        // 当前歌曲在新列表中不存在：停止播放 or 播放第一首
        _currentIndex = -1;
        _isPlaylistPrepared = false;

        await _player.stop();
      }
    }

    // 通知外部队列更新,外层监听当前队列，变化的时候ui状态跟着变化
    this.queue.add([..._playlist]);
  }
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems, {int startIndex = 0}) async {
    final existingIds = _playlist.map((e) => e.id).toSet();

    // 过滤出 playlist 中没有的
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id));

    _playlist.addAll(toAdd);

    if (!_isPlaylistPrepared && _playlist.isNotEmpty) {
      _currentIndex = 0;
      _isPlaylistPrepared = true;
    }

    queue.add(_playlist);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // 1. 已存在则直接退出，不重复添加
    final exists = _playlist.any((item) => item.id == mediaItem.id);
    if (exists) {
      return;
    }

    // 2. 不存在则添加
    _playlist.add(mediaItem);

    // 3. 如果是首次添加，初始化 index
    if (!_isPlaylistPrepared) {
      _currentIndex = 0;
      _isPlaylistPrepared = true;
    }

    // 4. 通知 queue 更新
    queue.add(_playlist);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);

    // 调整当前索引
    if (_currentIndex == index) {
      // 如果删除的是当前播放的歌曲
      if (_playlist.isEmpty) {
        _currentIndex = -1;
        _isPlaylistPrepared = false;
        await _player.stop();
        mediaItem.add(null);
      } else if (_currentIndex >= _playlist.length) {
        _currentIndex = _playlist.length - 1;
        await _playCurrentIndex();
      } else {
        await _playCurrentIndex();
      }
    } else if (_currentIndex > index) {
      _currentIndex--;
    }

    queue.add(_playlist);
  }

  @override
  Future<void> play() async {
    if (!_isPlaylistPrepared || _playlist.isEmpty) return;

    if (_player.playing) {
      return;
    }

    // 如果没有当前播放的歌曲，从第一首开始
    if (_currentIndex == -1 && _playlist.isNotEmpty) {
      _currentIndex = 0;
      await _playCurrentIndex();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    await _playCurrentIndex();
  }

  @override
  Future<void> skipToNext() async => _skipToNext();

  Future<void> _skipToNext() async {
    if (_playlist.isEmpty) return;

    final nextIndex = (_currentIndex + 1) % _playlist.length;
    _currentIndex = nextIndex;
    _playCurrentIndex();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    final prevIndex = _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    _currentIndex = prevIndex;
    await _playCurrentIndex();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.stop();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    _isPlaylistPrepared = false;
    return super.stop();
  }

  // 获取当前播放列表
  List<MediaItem> get playlist => List.unmodifiable(_playlist);

  // 清空播放列表
  Future<void> clearPlaylist() async {
    await _player.stop();
    _playlist.clear();
    _currentIndex = -1;
    _isPlaylistPrepared = false;
    queue.add(_playlist);
  }
}