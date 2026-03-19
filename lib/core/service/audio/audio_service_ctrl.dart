import 'dart:async';
import 'dart:io';
import 'dart:math'; // 用于随机播放
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

import '../../constants/app_constants.dart';
import '../../utils/data/other.dart';

// (AudioServiceSingleton 保持不变，省略不写)
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

  VideoController? _videoController;

  VideoController get videoController {
    _videoController ??= VideoController(_player);
    return _videoController!;
  }

  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  // --- 【新增】手动管理的播放状态 ---
  final List<MediaItem> _playlist = [];
  int _currentIndex = -1; // 当前正在播放的索引
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;
  // ---------------------------------

  AudioSession? _audioSession;
  bool _playInterrupted = false;
  double _normalVolume = 100.0;

  bool get _ignoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false) as bool;

  MyAudioHandler() {
    _listenMpvLogs();
    _initPlayerConfig();
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    // 取消了 _listenForCurrentItemChanges，因为底层不再管理 Playlist
  }

  Future<void> _initPlayerConfig() async {
    // 强制关闭底层 mpv 的列表循环，确保它播完一首就停，触发 completed 事件
    await _player.setPlaylistMode(PlaylistMode.none);

    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      try {
        await nativePlayer.setProperty("terminal", "yes");
        await nativePlayer.setProperty("msg-level", "all=v");
        final cacheDir = await OtherUtil.getPlayerTempPath();
        await nativePlayer.setProperty("demuxer-cache-dir", cacheDir);
        await nativePlayer.setProperty("af", "scaletempo2=max-speed=8");
        await nativePlayer.setProperty("network-timeout", "60");
        await nativePlayer.setProperty("stream-lavf-o", "reconnect=1,reconnect_streamed=1,reconnect_delay_max=5");
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

  Future<void> _applyAudioSessionConfiguration() async {
    // (逻辑保持不变)
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

  void _listenMpvLogs() {
    _player.stream.log.listen((event) {
      final logMessage = "[mpv] [${event.level}] ${event.prefix}: ${event.text}";
      if (event.level.contains('error')) {
        KikoenaiLogger().e(logMessage);
      } else if (event.level.contains('warn')) {
        KikoenaiLogger().w(logMessage);
      } else {
        debugPrint(logMessage);
      }
    });
  }

  Future<void> _setIgnoreAudioFocus(bool ignore) async {
    await _settingBox.put(StorageKeys.ignoreAudioFocus, ignore);
    await _applyAudioSessionConfiguration();
  }

  Future<void> _setupAudioSession() async {
    // (逻辑保持不变)
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

  //内部核心方法：播放指定索引的单曲 ---
  Future<void> _playIndex(int index, {Duration? position, bool autoPlay = true}) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final item = _playlist[index];

    // 手动更新 AudioService 状态
    mediaItem.add(item);
    playbackState.add(playbackState.value.copyWith(queueIndex: index));

    // 关键改变：永远只传单个 Media，不传 Playlist
    final media = _buildMedia(item);
    await _player.open(media, play: false);

    if (position != null && position > Duration.zero) {
      if (_player.state.duration == Duration.zero) {
        StreamSubscription? subscription;
        subscription = _player.stream.duration.listen((duration) {
          if (duration > Duration.zero) {
            _player.seek(position);
            subscription?.cancel();
          }
        });
      } else {
        await _player.seek(position);
      }
    }

    if (autoPlay) {
      await play();
    }
  }

  // --- 重写初始化与加载方法 ---
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

  Media _buildMedia(MediaItem item) {
    final url = item.extras!['url'] as String;
    return Media(url, extras: {'id': item.id});
  }

  // --- 重写队列管理，仅操作 Dart 集合，不再调用 _player.add/remove ---
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

    // 如果移除的是当前正在播放的曲目，自动播下一首或者停止
    if (index == _currentIndex) {
      if (_playlist.isEmpty) {
        await stop();
      } else {
        // 如果移除后到达列表末尾，播当前第一首，否则顺延播当前的 index
        final nextPlayIndex = index >= _playlist.length ? 0 : index;
        await _playIndex(nextPlayIndex);
      }
    } else if (index < _currentIndex) {
      // 移除的是前面的曲目，纠正 _currentIndex 偏移量
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

  // --- 重写切歌逻辑（包含循环与随机） ---
  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    int nextIndex = _currentIndex + 1;

    // 处理随机播放
    if (_shuffleMode == AudioServiceShuffleMode.all) {
      nextIndex = Random().nextInt(_playlist.length);
    } else {
      // 处理顺序/循环播放
      if (nextIndex >= _playlist.length) {
        if (_repeatMode == AudioServiceRepeatMode.all || _repeatMode == AudioServiceRepeatMode.group) {
          nextIndex = 0; // 列表循环
        } else {
          // 不循环，停在最后
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
          prevIndex = _playlist.length - 1; // 绕回最后一首
        } else {
          prevIndex = 0; // 强制播放第一首
        }
      }
    }
    await _playIndex(prevIndex);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _playIndex(index);
  }

  // --- 重写模式管理 ---
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

    // --- 核心改动：监听播放完成，手动切歌 ---
    _player.stream.completed.listen((completed) {
      if (completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));

        // 自动推进队列
        if (_repeatMode == AudioServiceRepeatMode.one) {
          // 单曲循环
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

  Future<void> toggleVideoDecoding(bool enable) async {
    // (逻辑保持不变)
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

      // 更新本地 Dart 队列
      final currentQueue = queue.value;
      final item = currentQueue.removeAt(oldIndex);
      currentQueue.insert(newIndex, item);

      _playlist.clear();
      _playlist.addAll(currentQueue);
      queue.add(List.from(_playlist));

      // 调整当前的 _currentIndex
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

      // 注意：不再调用 _player.move
    }
    return super.customAction(name, extras);
  }
}