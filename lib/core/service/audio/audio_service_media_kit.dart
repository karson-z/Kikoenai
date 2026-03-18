import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../constants/app_constants.dart';

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

  final List<MediaItem> _playlist = [];

  VideoController? _videoController;

  AudioSession? _audioSession;

  int _retryCount = 0;

  static const int _maxRetries = 3; // 最大重试次数

  int _currentIndex = -1;

  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  List<int> _shuffledIndices = [];

  bool _playInterrupted = false;

  double _normalVolume = 100.0;

  VideoController get videoController {
    _videoController ??= VideoController(_player);
    return _videoController!;
  }

  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  bool get _ignoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false) as bool;

  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100.0);

  double get volume => _normalVolume / 100.0;

  MyAudioHandler() {
    _initPlayerConfig();
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenErrorPlayState();
  }
  Future<void> _initPlayerConfig() async {
    // 强制类型检查：setProperty 仅在原生端（Android/iOS/macOS/Windows/Linux）有效，Web 端调用会崩溃
    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      try {
        // 1. 设置缓存目录
        // 请确保已导入你自己的 Utils 类
        final cacheDir = await OtherUtil.getPlayerTempPath();
        await nativePlayer.setProperty("demuxer-cache-dir", cacheDir);
        // 2. 音频变速不变调
        await nativePlayer.setProperty("af", "scaletempo2=max-speed=8");
        // 3. Android 平台专属配置
        if (Platform.isAndroid) {
          // 锁定软件最大增益，防止破音
          await nativePlayer.setProperty("volume-max", "100");

          final String audioOutputMode = _settingBox.get(
            StorageKeys.audioOutputMode,
            defaultValue: AppConstants.defaultAoMode,
          ) as String;
          final String safeAoMode = AppConstants.validAoModes.contains(audioOutputMode)
              ? audioOutputMode
              : AppConstants.defaultAoMode;

          // 直接将校验后的模式传给底层 mpv
          await nativePlayer.setProperty("ao", safeAoMode);
        }
        KikoenaiLogger().d("底层 mpv 参数配置注入成功");
      } catch (e) {
        KikoenaiLogger().e("底层 mpv 参数配置注入失败: $e");
      }
    }
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
        _skip(isNext: true, isAutoAdvance: true);
      }
    });

    _player.stream.rate.listen((rate) {
      playbackState.add(playbackState.value.copyWith(speed: rate));
    });
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

  void _listenForPositionChanges() {
    _player.stream.position.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
    _player.stream.buffer.listen((bufferedPosition) {
      playbackState.add(
          playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  void _listenErrorPlayState() {
    _player.stream.error.listen((e) async {
      KikoenaiLogger().e("播放异常: $e");

      if (_retryCount < _maxRetries) {
        _retryCount++;
        KikoenaiLogger().w("资源加载失败，尝试重连... ($_retryCount/$_maxRetries)");
        KikoenaiToast.error('加载失败，正在重试 ($_retryCount/$_maxRetries)');

        // 延迟 2 秒后重试，避免死循环请求打满网络和 CPU
        await Future.delayed(const Duration(seconds: 2));

        if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
          // 记录出错前的播放进度，以便重连后恢复
          final lastPosition = _player.state.position;

          final item = _playlist[_currentIndex];
          final media = _buildMedia(item);

          // 重新 open 资源
          await _player.open(media, play: false);

          if (lastPosition > Duration.zero) {
            await _player.seek(lastPosition);
          }

          // 重新获取焦点并播放
          await play();
        }
      } else {
        // 重试次数耗尽
        KikoenaiLogger().e("重连次数耗尽，停止播放");
        KikoenaiToast.error('连接彻底断开，请检查网络');
        _retryCount = 0; // 重置计数器
        await pause(); // 你也可以根据业务需求在这里调用 _skip(isNext: true, isAutoAdvance: true) 跳到下一首
      }
    });
  }

  Future<void> _applyAudioSessionConfiguration() async {
    if (_audioSession == null) return;

    if (_ignoreAudioFocus) {
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
      await _audioSession!.configure(const AudioSessionConfiguration.music());
    }
  }

  Future<void> _setIgnoreAudioFocus(bool ignore) async {
    await _settingBox.put(StorageKeys.ignoreAudioFocus, ignore);
    await _applyAudioSessionConfiguration();
  }

  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _applyAudioSessionConfiguration();

    _audioSession!.interruptionEventStream.listen((event) {
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

    _playlist.clear();
    _playlist.addAll(initialPlaylist);
    queue.add(List.from(_playlist));

    _repeatMode = repeatMode;
    _shuffleMode = shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    _currentIndex = initialIndex;

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }

    playbackState.add(playbackState.value.copyWith(
      repeatMode: _repeatMode,
      shuffleMode: _shuffleMode,
    ));

    if (_playlist.isEmpty) return;

    await _openCurrentMedia(initialPosition: initialPosition, autoPlay: false);
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

    _currentIndex = initialIndex;
    if (_shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }

    if (_playlist.isEmpty) return;

    try {
      await _openCurrentMedia(initialPosition: initialPosition, autoPlay: autoPlay);
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  Future<void> _openCurrentMedia({Duration? initialPosition, bool autoPlay = true}) async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

    final item = _playlist[_currentIndex];

    mediaItem.add(item);
    playbackState.add(playbackState.value.copyWith(queueIndex: _currentIndex));

    final media = _buildMedia(item);

    await _player.open(media, play: false);

    if (initialPosition != null && initialPosition > Duration.zero) {
      await _player.seek(initialPosition);
    }

    if (autoPlay) {
      await play();
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
    if (_shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final existingIds = _playlist.map((e) => e.id).toSet();
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id)).toList();
    if (toAdd.isEmpty) return;

    _playlist.addAll(toAdd);
    queue.add(List.from(_playlist));
    if (_shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);
    queue.add(List.from(_playlist));

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }

    if (_playlist.isEmpty) {
      _currentIndex = -1;
      await stop();
      return;
    }

    if (_currentIndex == index) {
      if (_currentIndex >= _playlist.length) {
        _currentIndex = 0;
      }
      await _openCurrentMedia(autoPlay: _player.state.playing);
    }
    else if (_currentIndex > index) {
      _currentIndex--;
      playbackState.add(playbackState.value.copyWith(queueIndex: _currentIndex));
    }
  }

  Future<void> clearPlaylist() async {
    _playlist.clear();
    _shuffledIndices.clear();
    _currentIndex = -1;
    queue.add([]);
    await stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _skip(isNext: true, isAutoAdvance: false);

  @override
  Future<void> skipToPrevious() => _skip(isNext: false, isAutoAdvance: false);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    await _openCurrentMedia(autoPlay: _player.state.playing);
  }

  Future<void> _skip({required bool isNext, required bool isAutoAdvance}) async {
    if (_playlist.isEmpty) return;

    int nextIndex = _calculateNextIndex(isNext: isNext, isAutoAdvance: isAutoAdvance);

    if (nextIndex == -1) {
      await stop();
      return;
    }

    _currentIndex = nextIndex;
    bool shouldPlay = _player.state.playing || isAutoAdvance;
    await _openCurrentMedia(autoPlay: shouldPlay);
  }

  int _calculateNextIndex({required bool isNext, required bool isAutoAdvance}) {
    if (_playlist.isEmpty) return -1;

    if (isAutoAdvance && _repeatMode == AudioServiceRepeatMode.one) {
      return _currentIndex;
    }

    List<int> currentOrder = _shuffleMode == AudioServiceShuffleMode.all
        ? _shuffledIndices
        : List.generate(_playlist.length, (i) => i);

    if (currentOrder.isEmpty) return -1;

    int positionInOrder = currentOrder.indexOf(_currentIndex);
    if (positionInOrder == -1) positionInOrder = 0;

    if (isNext) {
      if (positionInOrder < currentOrder.length - 1) {
        return currentOrder[positionInOrder + 1];
      } else {
        if (_repeatMode == AudioServiceRepeatMode.all || _repeatMode == AudioServiceRepeatMode.group) {
          return currentOrder[0];
        }
        return -1;
      }
    } else {
      if (positionInOrder > 0) {
        return currentOrder[positionInOrder - 1];
      } else {
        if (_repeatMode == AudioServiceRepeatMode.all || _repeatMode == AudioServiceRepeatMode.group) {
          return currentOrder[currentOrder.length - 1];
        }
        return currentOrder[0];
      }
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;
    if (shuffleMode == AudioServiceShuffleMode.all) {
      _generateShuffledIndices();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  void _generateShuffledIndices() {
    _shuffledIndices = List.generate(_playlist.length, (i) => i);
    _shuffledIndices.shuffle();

    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _shuffledIndices.remove(_currentIndex);
      _shuffledIndices.insert(0, _currentIndex);
    }
  }

  Future<void> toggleVideoDecoding(bool enable) async {
    try {
      if (enable) {
        await _player.setVideoTrack(VideoTrack.auto());
        KikoenaiLogger().d("视频画面解码已开启");
      } else {
        await _player.setVideoTrack(VideoTrack.no());
        KikoenaiLogger().d("视频画面解码已关闭，进入纯音频模式");
      }
    } catch (e) {
      KikoenaiLogger().e("切换视频轨道失败: $e");
    }
  }

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

      final item = _playlist.removeAt(oldIndex);
      _playlist.insert(newIndex, item);
      queue.add(List.from(_playlist));

      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }

      if (_shuffleMode == AudioServiceShuffleMode.all) {
        _generateShuffledIndices();
      }

      playbackState.add(playbackState.value.copyWith(
        queueIndex: _currentIndex,
      ));
    }
    return super.customAction(name, extras);
  }
}