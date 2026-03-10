import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:media_kit/media_kit.dart'; // 替换 just_audio 引入 media_kit
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:audio_session/audio_session.dart'; // 新增导入

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
  Player get player => _player;

  final List<MediaItem> _playlist = [];
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // --- Audio Session 相关变量 ---
  AudioSession? _audioSession;
  bool _playInterrupted = false;
  double _normalVolume = 100.0;

  MyAudioHandler() {
    _setupAudioSession(); // 初始化 AudioSession
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenForCurrentItemChanges();
    _listenErrorPlayState();
  }

  /// 初始化并监听音频焦点中断事件
  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession!.configure(const AudioSessionConfiguration.music());
    _audioSession!.interruptionEventStream.listen((event) {
      if (event.begin) {
        // 失去焦点
        switch (event.type) {
          case AudioInterruptionType.duck:
          // 其他应用播放短暂音效（如通知），降低当前音量至 30%
            _player.setVolume(_normalVolume * 0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
          // 其他应用开始持续播放音频（如接电话、播客），暂停当前播放
            if (_player.state.playing) {
              _player.pause();
              _playInterrupted = true;
            }
            break;
        }
      } else {
        // 恢复焦点
        switch (event.type) {
          case AudioInterruptionType.duck:
          // 恢复正常音量
            _player.setVolume(_normalVolume);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
          // 如果是因为失去焦点而暂停的，则恢复播放
            if (_playInterrupted) {
              play(); // 这里直接调用重写后的 play()，会重新申请 active 状态
              _playInterrupted = false;
            }
            break;
        }
      }
    });
  }

  @override
  Future<void> play() async {
    if (_audioSession != null) {
      // 播放前请求音频焦点
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
    _playInterrupted = false; // 用户主动暂停，清除被动暂停标记
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _playInterrupted = false;
    await _player.stop();
    await _audioSession?.setActive(false); // 停止时释放音频焦点
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
    await setShuffleMode(shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

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
      // 如果要求自动播放，需在 open 前通过重写的 play() 逻辑获取焦点
      await _player.open(playlist, play: false);
      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }
      if (autoPlay) {
        await play(); // 使用重写的 play() 确保获取焦点
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

      final currentSource = _player.state.playlist.medias.isNotEmpty;
      if (currentSource) {
        await Future.delayed(const Duration(milliseconds: 1500));
        play(); // 使用重写的 play()，不仅重试，还能重新确认焦点状态
      }
    });
  }

  Stream<double> get volumeStream => _player.stream.volume.map((v) => v / 100.0);

  double get volume => _normalVolume / 100.0;

  @override
  Future<void> setVolume(double v) {
    final targetVolume = (v * 100.0).clamp(0.0, 100.0);
    _normalVolume = targetVolume; // 保存用户的设定音量，防止被 duck 机制覆盖
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