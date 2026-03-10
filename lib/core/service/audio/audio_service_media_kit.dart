import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:media_kit/media_kit.dart'; // 替换 just_audio 引入 media_kit
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';

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

class MyAudioHandler extends BaseAudioHandler {
  // 1. 替换为 media_kit 的 Player
  final Player _player = Player();

  // 暴露给外层，用于给 VideoController 渲染视频画面
  Player get player => _player;

  final List<MediaItem> _playlist = [];
  int _retryCount = 0; // 当前重试次数
  static const int _maxRetries = 3; // 最大重试次数

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenForCurrentItemChanges();
    _listenErrorPlayState();
  }

  // 初始化播放状态
  Future<void> initPlayback({
    required List<MediaItem> initialPlaylist,
    required int initialIndex,
    required Duration initialPosition,
    required double volume,
    required AudioServiceRepeatMode repeatMode,
    required bool shuffleEnabled,
  }) async {
    await setVolume(volume);
    await setRepeatMode(repeatMode);
    await setShuffleMode(shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

    _playlist.clear();
    _playlist.addAll(initialPlaylist);
    queue.add(List.from(_playlist));

    if (_playlist.isEmpty) return;

    final children = _playlist.map(_buildMedia).toList();
    final playlist = Playlist(children, index: initialIndex);

    // 1. 先 open
    await _player.open(playlist, play: false);

    // 2. 解决 Seek 失效：等待 duration 变为有效值
    if (initialPosition > Duration.zero) {
      // 这里的逻辑是：如果当前还没有时长，就等它有。
      if (_player.state.duration == Duration.zero) {
        StreamSubscription? subscription;
        subscription = _player.stream.duration.listen((duration) {
          if (duration > Duration.zero) {
            _player.seek(initialPosition);
            subscription?.cancel(); // 跳转一次后取消监听
          }
        });
      } else {
        await _player.seek(initialPosition);
      }
    }
  }

  Future<void> loadPlaylist(
      List<MediaItem> items, {
        int initialIndex = 0,
        Duration? initialPosition,
        bool autoPlay = true,
      }) async {
    _playlist.clear();
    _playlist.addAll(items);
    queue.add(List.from(_playlist));

    final children = items.map(_buildMedia).toList();
    final playlist = Playlist(children, index: initialIndex);

    try {
      await _player.open(playlist, play: autoPlay);
      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  /// 核心映射：将 MediaItem 转换为 media_kit 的 Media
  Media _buildMedia(MediaItem item) {
    final url = item.extras!['url'] as String;
    // media_kit 底层直接支持网络和本地绝对路径，无需区分 Uri.parse 和 Uri.file
    return Media(
      url,
      // 巧妙的做法：将 mediaItem 的 id 存在 extras 中，方便在其它地方做业务对比
      extras: {'id': item.id},
    );
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    if (_playlist.any((item) => item.id == mediaItem.id)) return;

    _playlist.add(mediaItem);
    queue.add(List.from(_playlist));

    // 同步给底层播放器
    await _player.add(_buildMedia(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final existingIds = _playlist.map((e) => e.id).toSet();
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id)).toList();
    if (toAdd.isEmpty) return;

    _playlist.addAll(toAdd);
    queue.add(List.from(_playlist));

    // 循环添加至 media_kit 的队列末尾
    for (var item in toAdd) {
      await _player.add(_buildMedia(item));
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);
    queue.add(List.from(_playlist));

    await _player.remove(index);
  }

  Future<void> clearPlaylist() async {
    _playlist.clear();
    queue.add([]);
    // 用一个空的 Playlist 覆盖当前资源实现清空
    await _player.open(Playlist([]));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() => _player.next(); // 替换 seekToNext()

  @override
  Future<void> skipToPrevious() => _player.previous(); // 替换 seekToPrevious()

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.jump(index); // media_kit 的列表跳转 api 是 jump()
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));

    // 映射 media_kit 的 PlaylistMode
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setPlaylistMode(PlaylistMode.none);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setPlaylistMode(PlaylistMode.loop);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setPlaylistMode(PlaylistMode.single);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));

    if (shuffleMode == AudioServiceShuffleMode.all) {
      await _player.setShuffle(true);
    } else {
      await _player.setShuffle(false);
    }
  }

  // --- 监听与同步 (替换为 media_kit 的 stream) ---

  void _listenForCurrentItemChanges() {
    // 监听 playlist 变化，相当于 currentIndexStream
    _player.stream.playlist.listen((playlist) {
      final index = playlist.index;
      if (index >= 0 && index < _playlist.length) {
        final item = _playlist[index];
        mediaItem.add(item);
        playbackState.add(playbackState.value.copyWith(queueIndex: index));
      }
    });
  }

  void _listenForDurationChanges() {
    _player.stream.duration.listen((duration) {
      int currentIndex = _player.state.playlist.index;
      if (currentIndex >= 0 && currentIndex < _playlist.length) {
        final oldMediaItem = _playlist[currentIndex];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        _playlist[currentIndex] = newMediaItem;
        queue.add(_playlist);
        mediaItem.add(newMediaItem);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    // 1. 监听播放/暂停状态
    _player.stream.playing.listen((playing) {
      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
      ));
    });

    // 2. 监听缓冲与加载状态
    _player.stream.buffering.listen((buffering) {
      playbackState.add(playbackState.value.copyWith(
        processingState: buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      ));
    });

    // 3. 监听播放完成状态
    _player.stream.completed.listen((completed) {
      if (completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });

    // 4. 监听倍速
    _player.stream.rate.listen((rate) {
      playbackState.add(playbackState.value.copyWith(speed: rate));
    });
  }

  void _listenForPositionChanges() {
    _player.stream.position.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
    // media_kit 缓存流
    _player.stream.buffer.listen((bufferedPosition) {
      playbackState.add(
          playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  void _listenErrorPlayState() {
    _player.stream.error.listen((e) async {
      KikoenaiLogger().e("播放异常: $e");
      if (_retryCount >= _maxRetries) {
        KikoenaiToast.error('播放失败，已停止重试');
        _retryCount = 0;
        return;
      }

      _retryCount++;
      KikoenaiToast.error('连接断开，正在尝试第 $_retryCount/$_maxRetries 次重连...');

      // 取 media_kit 当前的数据源
      final currentSource = _player.state.playlist.medias.isNotEmpty;

      if (currentSource) {
        await Future.delayed(const Duration(milliseconds: 1500));
        // media_kit 重试机制直接调用 play() 即可
        _player.play();
      }
    });
  }

  // --- 音量控制转换 (关键点) ---

  // 如果你在 UI 层依然使用 0.0 - 1.0 传值，这里做 /100 兼容
  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100.0);

  double get volume => _player.state.volume / 100.0;

  Future<void> setVolume(double v) {
    // 拦截转换：将 UI 层的 0.0~1.0 转换为 media_kit 的 0.0~100.0
    final targetVolume = (v * 100.0).clamp(0.0, 100.0);
    return _player.setVolume(targetVolume);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'reorderQueue') {
      final int oldIndex = extras!['oldIndex'];
      final int newIndex = extras['newIndex'];

      int? currentIndex = playbackState.value.queueIndex;

      if (currentIndex != null) {
        if (oldIndex == currentIndex) {
          currentIndex = newIndex;
        } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
          currentIndex--;
        } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
          currentIndex++;
        }
      }

      final currentQueue = queue.value;
      final item = currentQueue.removeAt(oldIndex);
      currentQueue.insert(newIndex, item);
      queue.add(currentQueue);

      playbackState.add(playbackState.value.copyWith(
        queueIndex: currentIndex,
      ));

      await _player.move(oldIndex, newIndex);
    }
    return super.customAction(name, extras);
  }
}