import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/player/media_http_headers_registry.dart';
import 'package:kikoenai/core/service/player/player_service.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import '../../constants/app_constants.dart';
import 'package:kikoenai_core/kikoenai_core.dart' as core_models;
// ignore: unused_import
import 'package:kikoenai_core/core/utils/other.dart';

class AudioServiceSingleton {
  AudioServiceSingleton._();

  static late final AudioHandler _instance;
  static AudioHandler get instance {
    return _instance;
  }

  static Future<void> init() async {
    debugPrint("AudioServiceSingleton.init()");
    _instance = await AudioService.init(
      builder: () => MyAudioHandler(PlayerService.instance.player),
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
  /// 全局唯一的播放器实例，由调用方从 [PlayerService] 注入（主 isolate 创建）。
  ///
  /// 采用构造函数注入而非在类内直接访问 `PlayerService.instance`：
  /// 静态单例是 per-isolate 的，若 handler 未来被移到后台 isolate，
  /// 隐式访问会静默创建第二个 Player；显式注入会让跨 isolate 问题
  /// 在编译/构造时就暴露出来。
  final Player _player;

  late final AudioSession _audioSession;
  Box<dynamic> get _settingBox => AppStorage.settingsBox;
  final List<MediaItem> _playlist = [];
  int _currentIndex = -1;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;
  double _normalVolume = 100.0;
  bool _isInterrupted = false;
  bool _pausedByBackground = false;
  late final AppLifecycleListener _lifecycleListener;

  bool get isIgnoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false)
          as bool;

  MyAudioHandler(this._player) {
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleState,
    );
    _listenMpvLogs();
    _initPlayerConfig();
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenErrorStream();
  }

  bool get playInBackground =>
      _settingBox.get(StorageKeys.playerPlayInBackground, defaultValue: true)
          as bool;

  void _handleLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!playInBackground && _player.state.playing) {
        _pausedByBackground = true;
        _player.pause();
      }
      return;
    }

    if (state == AppLifecycleState.resumed && _pausedByBackground) {
      _pausedByBackground = false;
      if (!playInBackground) return;
      play();
    }
  }

  Future<void> _initPlayerConfig() async {
    await _player.setPlaylistMode(PlaylistMode.none);

    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      try {
        // 避免音视频文件没有对应的索引文件导致无法进行range跳转
        await nativePlayer.setProperty('hr-seek', 'yes');
        // media_kit 默认开启 cache-on-disk（把流缓存写入磁盘文件），在部分环境/版本下
        // 会因无法创建缓存文件而报 "lavf: Failed to create file cache" → 首次加载失败 →
        // keep-open 模式下 mpv 将其视为播放结束 → completed 事件 → 自动重开同一 URL
        // （表现为切换歌曲时同一地址被请求两次）。这里关闭磁盘缓存，改用内存缓存。
        await nativePlayer.setProperty('cache-on-disk', 'no');
        await nativePlayer.setProperty("demuxer-lavf-o", "fflags=+fastseek");
        final cacheDir = await OtherUtil.getPlayerTempPath();
        KikoenaiLogger().i("当前缓存路径:$cacheDir");
        await nativePlayer.setProperty("demuxer-cache-dir", cacheDir);
        await nativePlayer.setProperty("af", "scaletempo2=max-speed=8");

        if (Platform.isAndroid) {
          await nativePlayer.setProperty("volume-max", "100");
          final String audioOutputMode =
              _settingBox.get(
                    StorageKeys.audioOutputMode,
                    defaultValue: AppConstants.defaultAoMode,
                  )
                  as String;
          final String safeAoMode =
              AppConstants.validAoModes.contains(audioOutputMode)
              ? audioOutputMode
              : AppConstants.defaultAoMode;
          await nativePlayer.setProperty("ao", safeAoMode);
        }
        KikoenaiLogger().d("底层 mpv 参数配置注入成功");
      } catch (e) {
        KikoenaiLogger().e("底层 mpv 参数配置注入失败: $e");
      }
    }
  }

  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(const AudioSessionConfiguration.music());

    _audioSession.interruptionEventStream.listen((event) {
      if (isIgnoreAudioFocus) return;

      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(30.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_player.state.playing) {
              _player.pause();
              _isInterrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(100.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_isInterrupted) {
              play();
              _isInterrupted = false;
            }
            break;
        }
      }
    });

    _audioSession.becomingNoisyEventStream.listen((_) {
      pause();
      _isInterrupted = false;
    });
  }

  void _listenErrorStream() {
    _player.stream.error.listen((error) {
      KikoenaiToast.error('播放错误: $error');
    });
  }

  void _listenMpvLogs() {
    _player.stream.log.listen((event) {
      final logMessage =
          "[mpv] [${event.level}] ${event.prefix}: ${event.text}";
      if (event.level.contains('error')) {
        KikoenaiLogger().e(logMessage);
      } else if (event.level.contains('warn')) {
        KikoenaiLogger().w(logMessage);
      } else {
        KikoenaiLogger().i(logMessage);
      }
    });
  }

  @override
  Future<void> play() async {
    if (!isIgnoreAudioFocus) {
      final success = await _audioSession.setActive(true);
      if (!success) {
        KikoenaiLogger().w("无法获取音频焦点，播放可能会被系统静音或中断");
      }
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> _playIndex(
    int index, {
    Duration? position,
    bool autoPlay = true,
  }) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final item = _playlist[index];

    mediaItem.add(item);
    playbackState.add(
      playbackState.value.copyWith(
        queueIndex: index,
        processingState: AudioProcessingState.loading,
        errorCode: null,
        errorMessage: null,
      ),
    );

    final media = _buildMedia(item, startPosition: position);
    if (autoPlay && !isIgnoreAudioFocus) {
      final success = await _audioSession.setActive(true);
      if (!success) {
        autoPlay = false;
        KikoenaiLogger().w("获取音频焦点失败，已降级为只加载不播放");
      }
    }

    try {
      await _player.open(media, play: autoPlay);
    } catch (error) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.error,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
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
      shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );

    _playlist.clear();
    _playlist.addAll(initialPlaylist);
    queue.add(List.from(_playlist));

    if (_playlist.isEmpty) return;

    await _playIndex(initialIndex, position: initialPosition, autoPlay: false);
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

    if (_playlist.isEmpty) return;

    try {
      await _playIndex(
        initialIndex,
        position: initialPosition,
        autoPlay: autoPlay,
      );
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  Media _buildMedia(MediaItem item, {Duration? startPosition}) {
    final url = item.extras!['url'] as String;
    final httpHeaders = MediaHttpHeadersRegistry.instance.resolve(
      url: url,
      extras: item.extras ?? const <String, dynamic>{},
    );
    return Media(
      url,
      httpHeaders: httpHeaders,
      extras: {'id': item.id},
      start: startPosition,
    );
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    if (_playlist.any((item) => item.id == mediaItem.id)) return;
    _playlist.add(mediaItem);
    queue.add(List.from(_playlist));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final existingIds = _playlist.map((e) => e.id).toSet();
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id)).toList();
    if (toAdd.isEmpty) return;
    _playlist.addAll(toAdd);
    queue.add(List.from(_playlist));
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _playlist.removeAt(index);
    queue.add(List.from(_playlist));
    if (index == _currentIndex) {
      final nextPlayIndex = index >= _playlist.length ? 0 : index;
      await _playIndex(nextPlayIndex);
    } else if (index < _currentIndex) {
      _currentIndex--;
      playbackState.add(
        playbackState.value.copyWith(queueIndex: _currentIndex),
      );
    }
  }

  Future<void> clearPlaylist() async {
    _playlist.clear();
    _currentIndex = -1;
    queue.add([]);
    await _player.open(const Playlist([]));
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    int nextIndex = _currentIndex + 1;

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      nextIndex = Random().nextInt(_playlist.length);
    } else {
      if (nextIndex >= _playlist.length) {
        if (_repeatMode == AudioServiceRepeatMode.all ||
            _repeatMode == AudioServiceRepeatMode.group) {
          nextIndex = 0;
        } else {
          return;
        }
      }
    }
    await _playIndex(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    int prevIndex = _currentIndex - 1;

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      prevIndex = Random().nextInt(_playlist.length);
    } else {
      if (prevIndex < 0) {
        if (_repeatMode == AudioServiceRepeatMode.all ||
            _repeatMode == AudioServiceRepeatMode.group) {
          prevIndex = _playlist.length - 1;
        } else {
          prevIndex = 0;
        }
      }
    }
    await _playIndex(prevIndex);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _playIndex(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  void _listenForDurationChanges() {
    _player.stream.duration.listen((duration) {
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        final oldMediaItem = _playlist[_currentIndex];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        _playlist[_currentIndex] = newMediaItem;
        queue.add(List.from(_playlist));
        mediaItem.add(newMediaItem);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.stream.playing.listen((playing) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          androidCompactActionIndices: const [0, 1, 3],
        ),
      );
    });

    _player.stream.buffering.listen((buffering) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: buffering
              ? AudioProcessingState.buffering
              : AudioProcessingState.ready,
        ),
      );
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.completed,
          ),
        );

        if (_repeatMode == AudioServiceRepeatMode.one) {
          _playIndex(_currentIndex);
        } else {
          skipToNext();
        }
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
        playbackState.value.copyWith(bufferedPosition: bufferedPosition),
      );
    });
  }

  Stream<double> get volumeStream =>
      _player.stream.volume.map((v) => v / 100.0);

  double get volume => _normalVolume / 100.0;

  Future<void> setVolume(double v) {
    final targetVolume = (v * 100.0).clamp(0.0, 100.0);
    _normalVolume = targetVolume;
    return _player.setVolume(targetVolume);
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'toggleVideoDecoding') {
      final bool enable = extras?['enable'] ?? false;
      await PlayerService.instance.toggleVideoDecoding(enable);
      return;
    }
    if (name == 'reorderQueue') {
      final int oldIndex = extras!['oldIndex'];
      final int newIndex = extras['newIndex'];

      final currentQueue = queue.value;
      final item = currentQueue.removeAt(oldIndex);
      currentQueue.insert(newIndex, item);

      _playlist.clear();
      _playlist.addAll(currentQueue);
      queue.add(List.from(_playlist));

      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }

      playbackState.add(
        playbackState.value.copyWith(queueIndex: _currentIndex),
      );
    }
    return super.customAction(name, extras);
  }
}
