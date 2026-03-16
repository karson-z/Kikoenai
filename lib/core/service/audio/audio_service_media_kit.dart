import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  final Player _player = Player();

  // 这里不应该直接暴露 _player 实例给到外部调用
  VideoController? _videoController;

  VideoController get videoController {
    _videoController ??= VideoController(_player);
    return _videoController!;
  }

  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  final List<MediaItem> _playlist = [];

  int _retryCount = 0;

  static const int _maxRetries = 3;

  AudioSession? _audioSession;

  bool _playInterrupted = false;

  double _normalVolume = 100.0;

  // 实时读取是否忽略音频焦点的配置
  bool get _ignoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false) as bool;

  MyAudioHandler() {
    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      nativePlayer.setProperty('network-timeout', '15');
    }
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenForCurrentItemChanges();
    // _listenErrorPlayState();
  }

  /// 动态应用当前的 AudioSession 配置
  Future<void> _applyAudioSessionConfiguration() async {
    if (_audioSession == null) return;

    if (_ignoreAudioFocus) {
      // 开启忽略：允许与其他音频混音播放 (Mix with others)
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
        AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
        AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
        AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
    } else {
      // 关闭忽略：恢复默认独占播放的音乐模式
      await _audioSession!.configure(const AudioSessionConfiguration.music());
    }
  }

  /// 供 UI 调用的设置方法，更新 Hive 并刷新配置
  Future<void> _setIgnoreAudioFocus(bool ignore) async {
    await _settingBox.put(StorageKeys.ignoreAudioFocus, ignore);
    await _applyAudioSessionConfiguration();
  }

  /// 初始化并监听音频焦点中断事件
  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;

    // 初始化时，根据 Hive 中的设置应用对应的音频策略
    await _applyAudioSessionConfiguration();

    _audioSession!.interruptionEventStream.listen((event) {
      // 拦截：如果开启了忽略焦点，跳过系统的中断事件
      if (_ignoreAudioFocus) return;

      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(_normalVolume * 0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_player.state.playing) {
              _player.pause();
              _playInterrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(_normalVolume);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_playInterrupted) {
              play();
              _playInterrupted = false;
            }
            break;
        }
      }
    });
  }

  @override
  Future<void> play() async {
    if (_ignoreAudioFocus) {
      // 忽略焦点模式：不关心是否独占，直接播放
      await _audioSession?.setActive(true);
      await _player.play();
      return;
    }

    if (_audioSession != null) {
      final success = await _audioSession!.setActive(true);
      if (success) {
        await _player.play();
      } else {
        KikoenaiLogger().e("获取音频焦点失败，无法播放");
      }
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    _playInterrupted = false;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _playInterrupted = false;
    await _player.stop();
    await _audioSession?.setActive(false);
    _videoController = null;
    return super.stop();
  }

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
    await setShuffleMode(
        shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

    _playlist.clear();
    _playlist.addAll(initialPlaylist);
    queue.add(List.from(_playlist));

    if (_playlist.isEmpty) return;

    final children = _playlist.map(_buildMedia).toList();
    final playlist = Playlist(children, index: initialIndex);

    await _player.open(playlist, play: false);

    if (initialPosition > Duration.zero) {
      if (_player.state.duration == Duration.zero) {
        StreamSubscription? subscription;
        subscription = _player.stream.duration.listen((duration) {
          if (duration > Duration.zero) {
            _player.seek(initialPosition);
            subscription?.cancel();
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
      await _player.open(playlist, play: false);
      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }
      if (autoPlay) {
        await play(); // 使用重写的 play() 确保走焦点逻辑
      }
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  Media _buildMedia(MediaItem item) {
    final url = item.extras!['url'] as String;
    return Media(url, extras: {'id': item.id});
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    if (_playlist.any((item) => item.id == mediaItem.id)) return;
    _playlist.add(mediaItem);
    queue.add(List.from(_playlist));
    await _player.add(_buildMedia(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final existingIds = _playlist.map((e) => e.id).toSet();
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id)).toList();
    if (toAdd.isEmpty) return;
    _playlist.addAll(toAdd);
    queue.add(List.from(_playlist));
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
    await _player.open(Playlist([]));
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.jump(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
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
    await _player.setShuffle(shuffleMode == AudioServiceShuffleMode.all);
  }

  void _listenForCurrentItemChanges() {
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

    _player.stream.buffering.listen((buffering) {
      playbackState.add(playbackState.value.copyWith(
        processingState: buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      ));
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });

    _player.stream.rate.listen((rate) {
      playbackState.add(playbackState.value.copyWith(speed: rate));
    });
  }

  void _listenForPositionChanges() {
    _player.stream.position.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
    _player.stream.buffer.listen((bufferedPosition) {
      playbackState.add(
          playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  // void _listenErrorPlayState() {
  //   _player.stream.error.listen((e) async {
  //     KikoenaiLogger().e("播放异常: $e");
  //     if (_retryCount >= _maxRetries) {
  //       KikoenaiToast.error('播放失败，已停止重试');
  //       _retryCount = 0;
  //       return;
  //     }
  //
  //     _retryCount++;
  //     KikoenaiToast.error('连接断开，正在尝试第 $_retryCount/$_maxRetries 次重连...');
  //
  //     final currentSource = _player.state.playlist.medias.isNotEmpty;
  //     if (currentSource) {
  //       await Future.delayed(const Duration(milliseconds: 1500));
  //       play();
  //     }
  //   });
  // }
  Future<void> toggleVideoDecoding(bool enable) async {
    try {
      if (enable) {
        // 唤醒视频解码器，mpv 会自动将画面同步到当前音频的时间戳
        await _player.setVideoTrack(VideoTrack.auto());
        KikoenaiLogger().d("视频画面解码已开启");
      } else {
        // 挂起视频解码器，保留纯音频播放，大幅降低功耗
        await _player.setVideoTrack(VideoTrack.no());
        KikoenaiLogger().d("视频画面解码已关闭，进入纯音频模式");
      }
    } catch (e) {
      KikoenaiLogger().e("切换视频轨道失败: $e");
    }
  }

  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100.0);

  double get volume => _normalVolume / 100.0;

  Future<void> setVolume(double v) {
    final targetVolume = (v * 100.0).clamp(0.0, 100.0);
    _normalVolume = targetVolume;
    return _player.setVolume(targetVolume);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setIgnoreAudioFocus') {
      final bool ignore = extras?['ignore'] ?? false;
      await _setIgnoreAudioFocus(ignore);
      return;
    }
    if (name == 'toggleVideoDecoding') {
      final bool enable = extras?['enable'] ?? false;
      await toggleVideoDecoding(enable);
      return;
    }
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