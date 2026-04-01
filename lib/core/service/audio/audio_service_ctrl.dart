import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../constants/app_constants.dart';
import '../../utils/data/other.dart';

/// 全局单例的 AudioService 管理器
///
/// 负责初始化 [AudioService] 并对外提供 [AudioHandler] 实例的访问。
class AudioServiceSingleton {
  AudioServiceSingleton._();

  static late final AudioHandler _instance;

  /// 获取当前的 [AudioHandler] 实例
  static AudioHandler get instance {
    return _instance;
  }

  /// 初始化 AudioService 及底层通知配置
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

/// 自定义音频处理器，连接 UI 状态与底层 media_kit 播放器。
///
/// 采用由 Dart 业务层全权接管播放队列管理的策略，
/// 从而避免底层播放器因网络等异常造成的循环跳集问题。
class MyAudioHandler extends BaseAudioHandler {
  /// 底层媒体播放器实例
  final Player _player = Player();

  VideoController? _videoController;

  /// 视频控制器，供 UI 层挂载视频画面时使用
  VideoController get videoController {
    _videoController ??= VideoController(_player);
    return _videoController!;
  }

  /// 本地配置存储
  Box<dynamic> get _settingBox => AppStorage.settingsBox;

  /// 当前播放列表
  final List<MediaItem> _playlist = [];

  /// 当前播放曲目的索引
  int _currentIndex = -1;

  /// 循环模式
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  /// 随机模式
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  /// 音频会话控制器，用于处理系统音频焦点
  AudioSession? _audioSession;

  /// 标识播放是否被系统音频焦点中断
  bool _playInterrupted = false;

  /// 标识播放是否因外部设备断开而暂停
  bool _pausedByDeviceDisconnect = false;

  /// 记录设备断开的时间，用于过滤系统路由抖动
  DateTime? _lastDisconnectTime;

  /// 路由变更防抖定时器
  Timer? _debounceTimer;

  StreamSubscription? _noisySubscription;
  StreamSubscription? _deviceSubscription;

  /// 设定的正常播放音量 (0-100)
  double _normalVolume = 100.0;

  /// 实时读取是否忽略音频焦点的用户配置
  bool get _ignoreAudioFocus =>
      _settingBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false) as bool;

  MyAudioHandler() {
    _listenMpvLogs();
    _initPlayerConfig();
    _setupAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
  }

  /// 初始化底层 mpv 播放器参数
  Future<void> _initPlayerConfig() async {
    // 强制关闭底层 mpv 的列表功能，仅作为单例播放器使用
    await _player.setPlaylistMode(PlaylistMode.none);

    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      try {
        await nativePlayer.setProperty("terminal", "yes");
        // await nativePlayer.setProperty("msg-level", "all=v");
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

  /// 动态应用当前的 AudioSession 策略配置
  Future<void> _applyAudioSessionConfiguration() async {
    if (_audioSession == null) return;

    if (_ignoreAudioFocus) {
      // 开启忽略焦点：允许与其他音频混音播放
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
      // 关闭忽略焦点：恢复默认独占播放模式
      await _audioSession!.configure(const AudioSessionConfiguration.music());
    }
  }

  /// 监听并过滤底层播放器的日志流
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

  /// 切换并持久化音频焦点忽略设置
  Future<void> _setIgnoreAudioFocus(bool ignore) async {
    await _settingBox.put(StorageKeys.ignoreAudioFocus, ignore);
    await _applyAudioSessionConfiguration();
  }

  /// 初始化音频会话并监听焦点中断与设备变更事件
  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _applyAudioSessionConfiguration();

    // 1. 监听音频焦点中断（如来电、通知等）
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

    // 2. 监听外部设备断开事件
    _noisySubscription = _audioSession!.becomingNoisyEventStream.listen((_) {
      if (_player.state.playing) {
        _player.pause();
        _pausedByDeviceDisconnect = true;
        _lastDisconnectTime = DateTime.now();
      }
    });

    // 3. 监听设备状态变更，处理自动恢复播放
    _deviceSubscription = _audioSession!.devicesChangedEventStream.listen((event) {
      if (event.devicesAdded.isEmpty || !_pausedByDeviceDisconnect) return;

      final isRealHeadset = event.devicesAdded.any((d) =>
      d.isOutput && (
          d.type == AudioDeviceType.bluetoothA2dp ||
              d.type == AudioDeviceType.wiredHeadset ||
              d.type == AudioDeviceType.wiredHeadphones ||
              d.type == AudioDeviceType.bluetoothLe ||
              d.type == AudioDeviceType.usbAudio
      )
      );

      if (isRealHeadset) {
        final now = DateTime.now();
        final timeSinceDisconnect = _lastDisconnectTime != null
            ? now.difference(_lastDisconnectTime!).inMilliseconds
            : 0;

        if (timeSinceDisconnect < 1500) {
          _pausedByDeviceDisconnect = false;
          return;
        }

        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (_pausedByDeviceDisconnect) {
            play();
            _pausedByDeviceDisconnect = false;
          }
        });
      }
    });
  }

  @override
  Future<void> play() async {
    _pausedByDeviceDisconnect = false;

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
    _pausedByDeviceDisconnect = false;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _playInterrupted = false;
    _pausedByDeviceDisconnect = false;
    await _player.stop();
    await _audioSession?.setActive(false);
    _videoController = null;
    return super.stop();
  }

  /// 清理控制器资源
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    _noisySubscription?.cancel();
    _deviceSubscription?.cancel();
    await _player.dispose();
  }

  /// 播放列表中指定索引的曲目
  ///
  /// [index] 目标曲目在 [_playlist] 中的索引
  /// [position] 初始播放跳转位置
  /// [autoPlay] 加载后是否立即播放
  Future<void> _playIndex(int index, {Duration? position, bool autoPlay = true}) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final item = _playlist[index];

    mediaItem.add(item);
    playbackState.add(playbackState.value.copyWith(queueIndex: index));

    final media = _buildMedia(item, startPosition: position);

    await _player.open(media, play: false);

    if (autoPlay) {
      await play();
    }
  }

  /// 初始化并重置播放环境
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

  /// 加载播放列表并开始播放
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

  /// 构建底层所需使用的媒体对象
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

  /// 清空当前播放列表并释放媒体
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

  /// 监听底层媒体时长变化并更新列表数据
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

  /// 监听底层播放事件并同步到 AudioService 状态机
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

    // 播放完毕事件监听与自动跳转
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

  /// 监听并同步播放位置与缓冲进度
  void _listenForPositionChanges() {
    _player.stream.position.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
    _player.stream.buffer.listen((bufferedPosition) {
      playbackState.add(
          playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  /// 控制硬件视频解码器的开启与关闭，以优化功耗
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

  /// 获取标准化音量流（0.0 ~ 1.0）
  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100.0);

  /// 获取当前标准化音量（0.0 ~ 1.0）
  double get volume => _normalVolume / 100.0;

  /// 设定播放音量
  ///
  /// [v] 标准化音量，取值范围 0.0 ~ 1.0
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