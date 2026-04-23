import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/player/player_service.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import '../../constants/app_constants.dart';
import '../../utils/data/other.dart';

/// 全局单例的 AudioService 管理器
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

/// 自定义音频处理器，连接系统服务状态与底层播放引擎。
class MyAudioHandler extends BaseAudioHandler  {
  /// 引用全局的媒体播放引擎
  final Player _player = PlayerService.instance.player;
  late final AudioSession _audioSession;
  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  final List<MediaItem> _playlist = [];

  int _currentIndex = -1;

  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  double _normalVolume = 100.0;

  bool get isIgnoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false) as bool;

  bool _isInterrupted = false;

  MyAudioHandler() {
    _listenMpvLogs();
    _initPlayerConfig();
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenErrorStream();
  }

  Future<void> _initPlayerConfig() async {
    await _player.setPlaylistMode(PlaylistMode.none);

    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      try {
        // 向 FFmpeg 的解复用器 (lavf) 注入 fastseek 标志
        // 这会强制 FFmpeg 放弃构建完整索引，对于缺乏索引的文件直接基于比特率进行估算 Range 跳转
        await nativePlayer.setProperty("demuxer-lavf-o", "fflags=+fastseek");
        final cacheDir = await OtherUtil.getPlayerTempPath();
        KikoenaiLogger().i("当前缓存路径:$cacheDir");
        await nativePlayer.setProperty("demuxer-cache-dir", cacheDir);
        await nativePlayer.setProperty('demuxer-max-bytes', '500000000');
        await nativePlayer.setProperty("af", "scaletempo2=max-speed=8");

        if (Platform.isAndroid) {
          await nativePlayer.setProperty("volume-max", "100");
          final String audioOutputMode = _settingBox.get(
            StorageKeys.audioOutputMode,
            defaultValue: AppConstants.defaultAoMode,
          ) as String;
          final String safeAoMode = AppConstants.validAoModes.contains(audioOutputMode)
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
  // 自定义音频焦点初始化
  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    // 配置为标准的“音乐播放器”模式
    await _audioSession.configure(const AudioSessionConfiguration.music());

    // 监听系统焦点被抢占（如来电、其他软件播放音乐）
    _audioSession.interruptionEventStream.listen((event) {
      // 依赖类级别的 getter 确保状态实时同步
      if (isIgnoreAudioFocus) return;

      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(30.0); // 压低音量
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
          // 如果当前确实在播放，才标记为被系统打断
            if (_player.state.playing) {
              _player.pause(); // 强制暂停
              _isInterrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(100.0); // 恢复音量
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
          // 只有确实是被系统打断的，系统恢复时我们才恢复播放
            if (_isInterrupted) {
              play();
              _isInterrupted = false;
            }
            break;
        }
      }
    });

    // 监听耳机拔出事件（必须暂停）
    _audioSession.becomingNoisyEventStream.listen((_) {
      pause();
      _isInterrupted = false;
    });
  }

  void _listenErrorStream() {
    _player.stream.error.listen((error){
      KikoenaiToast.error(
          '播放错误: $error'
      );
    });
  }

  void _listenMpvLogs() {
    _player.stream.log.listen((event) {
      final logMessage = "[mpv] [${event.level}] ${event.prefix}: ${event.text}";
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

  @override
  Future<void> stop() async {
    await _player.stop();
    await _audioSession.setActive(false);
    return super.stop();
  }

  Future<void> _playIndex(int index, {Duration? position, bool autoPlay = true}) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final item = _playlist[index];

    mediaItem.add(item);
    playbackState.add(playbackState.value.copyWith(queueIndex: index));

    final media = _buildMedia(item, startPosition: position);
    if (autoPlay && !isIgnoreAudioFocus) {
      final success = await _audioSession.setActive(true);
      if (!success) {
        autoPlay = false;
        KikoenaiLogger().w("获取音频焦点失败，已降级为只加载不播放");
      }
    }

    await _player.open(media, play: autoPlay);
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
      await _playIndex(initialIndex, position: initialPosition, autoPlay: autoPlay);
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  Media _buildMedia(MediaItem item, {Duration? startPosition}) {
    final url = item.extras!['url'] as String;
    return Media(
      url,
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
      if (_playlist.isEmpty) {
        await stop();
      } else {
        final nextPlayIndex = index >= _playlist.length ? 0 : index;
        await _playIndex(nextPlayIndex);
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
      playbackState.add(playbackState.value.copyWith(queueIndex: _currentIndex));
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
        if (_repeatMode == AudioServiceRepeatMode.all || _repeatMode == AudioServiceRepeatMode.group) {
          nextIndex = 0;
        } else {
          await stop();
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
        if (_repeatMode == AudioServiceRepeatMode.all || _repeatMode == AudioServiceRepeatMode.group) {
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
          playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
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
    // 移除了与音频焦点相关的 customAction ('setIgnoreAudioFocus')
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

      playbackState.add(playbackState.value.copyWith(
        queueIndex: _currentIndex,
      ));
    }
    return super.customAction(name, extras);
  }
}