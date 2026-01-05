// import 'package:flutter/cupertino.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
//
// class AudioServiceSingleton {
//   AudioServiceSingleton._();
//   static late final AudioHandler _instance;
//
//   static AudioHandler get instance {
//     return _instance;
//   }
//
//   static Future<void> init() async {
//     debugPrint("AudioServiceSingleton.init()");
//     _instance = await AudioService.init(
//       builder: () => MyAudioHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.karson.kikoenai.audio',
//         androidNotificationChannelName: 'Kikoenai',
//         androidNotificationOngoing: false,
//         androidStopForegroundOnPause: false,
//         androidShowNotificationBadge: true,
//       ),
//     );
//   }
// }
// class MyAudioHandler extends BaseAudioHandler {
//   final AudioPlayer _player = AudioPlayer();
//   bool _alreadyCompleted = false;
//   // 自己维护的播放列表
//   final List<MediaItem> _playlist = [];
//   int _currentIndex = -1;
//   bool _isPlaylistPrepared = false;
//   // 获取当前播放列表
//   List<MediaItem> get playlist => List.unmodifiable(_playlist);
//
//   MyAudioHandler() {
//     _notifyAudioHandlerAboutPlaybackEvents();
//     _listenForDurationChanges();
//     _listenForPlaybackCompletion();
//     _listenForPositionChanges();
//     _listenErrorPlayState();
//   }
//   int get currentIndex => _currentIndex;
//
//   Future<void> setCurrentIndex(int index) async {
//     _currentIndex = index;
//
//     if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
//       return;
//     }
//
//     // 1. 更新当前媒体项信息
//     final newMediaItem = _playlist[_currentIndex];
//     mediaItem.add(newMediaItem);
//     // 2. 更新队列索引给 AudioService
//     playbackState.add(playbackState.value.copyWith(queueIndex: _currentIndex));
//
//     // 3. 准备播放源
//     try {
//       final url = newMediaItem.extras!['url'] as String;
//       await _player.setAudioSource(_buildAudioSource(url));
//     } catch (e) {
//       debugPrint("Error setting audio source: $e");
//       playbackState.add(playbackState.value.copyWith(
//         processingState: AudioProcessingState.error,
//         // 将错误信息传递给UI层
//         errorMessage: "无法加载音频，请检查网络或文件是否有效。",
//       ));
//     }
//   }
//   AudioSource _buildAudioSource(String url) {
//     final bool isNetwork =
//         url.startsWith('http://') || url.startsWith('https://');
//
//     if (isNetwork) {
//       return AudioSource.uri(Uri.parse(url));
//     } else {
//       // 本地文件路径（Windows / macOS / Linux 都安全）
//       return AudioSource.file(url);
//     }
//   }
//   // 播放
//   Stream<double> get volumeStream => _player.volumeStream;
//   double get volume => _player.volume;
//   Future<void> setVolume(double v) => _player.setVolume(v);
//
//   // 播放当前索引的歌曲
//   Future<void> _playCurrentIndex() async {
//     if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
//       return;
//     }
//
//     final newMediaItem = _playlist[_currentIndex];
//     final url = newMediaItem.extras!['url'] as String;
//
//     mediaItem.add(newMediaItem);
//     playbackState.add(playbackState.value.copyWith(
//       queueIndex: _currentIndex,
//       playing: false,
//       processingState: AudioProcessingState.loading,
//     ));
//
//     try {
//       await _player.setAudioSource(_buildAudioSource(url));
//
//       playbackState.add(playbackState.value.copyWith(
//         queueIndex: _currentIndex,
//       ));
//
//       await _player.play();
//     } catch (e) {
//       debugPrint("Error playing audio: $e");
//       playbackState.add(playbackState.value.copyWith(
//         processingState: AudioProcessingState.error,
//         // 将错误信息传递给UI层
//         errorMessage: "无法加载音频，请检查网络或文件是否有效。",
//       ));
//     }
//   }
//
//   void _notifyAudioHandlerAboutPlaybackEvents() {
//     _player.playbackEventStream.listen((event) {
//       final playing = _player.playing;
//       // 更新 AudioService 播放状态
//       playbackState.add(playbackState.value.copyWith(
//         controls: [
//           MediaControl.skipToPrevious,
//           if (playing) MediaControl.pause else MediaControl.play,
//           MediaControl.stop,
//           MediaControl.skipToNext,
//         ],
//         systemActions: const {MediaAction.seek},
//         androidCompactActionIndices: const [0, 1, 3],
//         processingState: const {
//           ProcessingState.idle: AudioProcessingState.idle,
//           ProcessingState.loading: AudioProcessingState.loading,
//           ProcessingState.buffering: AudioProcessingState.buffering,
//           ProcessingState.ready: AudioProcessingState.ready,
//           ProcessingState.completed: AudioProcessingState.completed,
//         }[_player.processingState]!,
//         repeatMode: const {
//           LoopMode.off: AudioServiceRepeatMode.none,
//           LoopMode.one: AudioServiceRepeatMode.one,
//           LoopMode.all: AudioServiceRepeatMode.all,
//         }[_player.loopMode]!,
//         shuffleMode: AudioServiceShuffleMode.none,
//         playing: playing,
//         // updatePosition: _player.position,
//         // bufferedPosition: _player.bufferedPosition,
//         speed: _player.speed,
//         queueIndex: _currentIndex,
//       ));
//     });
//   }
//   void _listenErrorPlayState () {
//      _player.errorStream.listen((e) {
//        KikoenaiLogger().e("${e.message}");
//      });
//   }
//   void _listenForPositionChanges() {
//     // just_audio 提供了一个专门用于播放进度监听的流，需要单独进行更新，而不是加入到播放事件流监听中进行更新
//     // 由于安卓和windows底层使用的播放器不同，playbackEventStream 在移动端被操作系统节流变成每隔3秒更新一次
//     _player.positionStream.listen((position) {
//       playbackState.add(playbackState.value.copyWith(
//         updatePosition: position,
//       ));
//     });
//
//     _player.bufferedPositionStream.listen((bufferedPosition) {
//       playbackState.add(playbackState.value.copyWith(
//         bufferedPosition: bufferedPosition,
//       ));
//     });
//   }
//   void _listenForDurationChanges() {
//     _player.durationStream.listen((duration) {
//       if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
//         final oldMediaItem = _playlist[_currentIndex];
//         final newMediaItem = oldMediaItem.copyWith(duration: duration);
//         _playlist[_currentIndex] = newMediaItem;
//         queue.add(_playlist);
//         mediaItem.add(newMediaItem);
//       }
//     });
//   }
//   void _listenForPlaybackCompletion() {
//     _player.playerStateStream.listen((state) {
//       if (state.processingState == ProcessingState.completed) {
//         if (_alreadyCompleted) return;
//         _alreadyCompleted = true;
//         // 获取当前的循环模式
//         final mode = playbackState.value.repeatMode;
//         if (mode == AudioServiceRepeatMode.one) {
//           return;
//         }
//         // 判断是否是列表最后一首
//         final isLast = _currentIndex >= _playlist.length - 1;
//
//         if (mode == AudioServiceRepeatMode.none && isLast) {
//           // 不循环模式 && 最后一首 -> 停止播放，重置到开头或不做处理
//           _player.seek(Duration.zero);
//           pause();
//         } else {
//           // 列表循环 OR (不循环且不是最后一首) -> 播放下一首
//           _skipToNext();
//         }
//       }
//
//       if (state.processingState == ProcessingState.ready ||
//           state.processingState == ProcessingState.buffering ||
//           state.processingState == ProcessingState.loading) {
//         _alreadyCompleted = false;
//       }
//     });
//   }
//   @override
//   Future<void> updateQueue(List<MediaItem> queue) async {
//     // 记录当前播放歌曲
//     MediaItem? current = (_currentIndex >= 0 && _currentIndex < _playlist.length)
//         ? _playlist[_currentIndex]
//         : null;
//
//     // 替换播放列表
//     _playlist
//       ..clear()
//       ..addAll(queue);
//
//     // 重新计算当前歌曲的索引
//     if (current != null) {
//       final newIndex = _playlist.indexWhere((it) => it.id == current.id);
//
//       if (newIndex != -1) {
//         _currentIndex = newIndex;
//       } else {
//         // 当前歌曲在新列表中不存在：停止播放 or 播放第一首
//         _currentIndex = -1;
//         _isPlaylistPrepared = false;
//
//         await _player.stop();
//       }
//     }
//
//     // 通知外部队列更新,外层监听当前队列，变化的时候ui状态跟着变化
//     this.queue.add([..._playlist]);
//   }
//   @override
//   Future<void> addQueueItems(List<MediaItem> mediaItems, {int startIndex = 0}) async {
//     final existingIds = _playlist.map((e) => e.id).toSet();
//
//     // 过滤出 playlist 中没有的
//     final toAdd = mediaItems.where((e) => !existingIds.contains(e.id));
//
//     _playlist.addAll(toAdd);
//
//     if (!_isPlaylistPrepared && _playlist.isNotEmpty) {
//       _currentIndex = 0;
//       _isPlaylistPrepared = true;
//     }
//
//     queue.add(_playlist);
//   }
//
//   @override
//   Future<void> addQueueItem(MediaItem mediaItem) async {
//     // 1. 已存在则直接退出，不重复添加
//     final exists = _playlist.any((item) => item.id == mediaItem.id);
//     if (exists) {
//       return;
//     }
//
//     // 2. 不存在则添加
//     _playlist.add(mediaItem);
//
//     // 3. 如果是首次添加，初始化 index
//     if (!_isPlaylistPrepared) {
//       _currentIndex = 0;
//       _isPlaylistPrepared = true;
//     }
//
//     // 4. 通知 queue 更新
//     queue.add(_playlist);
//   }
//
//   @override
//   Future<void> removeQueueItemAt(int index) async {
//     if (index < 0 || index >= _playlist.length) return;
//
//     _playlist.removeAt(index);
//
//     // 调整当前索引
//     if (_currentIndex == index) {
//       // 如果删除的是当前播放的歌曲
//       if (_playlist.isEmpty) {
//         _currentIndex = -1;
//         _isPlaylistPrepared = false;
//         await _player.stop();
//         mediaItem.add(null);
//       } else if (_currentIndex >= _playlist.length) {
//         _currentIndex = _playlist.length - 1;
//         await _playCurrentIndex();
//       } else {
//         await _playCurrentIndex();
//       }
//     } else if (_currentIndex > index) {
//       _currentIndex--;
//     }
//
//     queue.add(_playlist);
//   }
//
//   @override
//   Future<void> play() async {
//     if (!_isPlaylistPrepared || _playlist.isEmpty) return;
//
//     if (_player.playing) {
//       return;
//     }
//
//     // 如果没有当前播放的歌曲，从第一首开始
//     if (_currentIndex == -1 && _playlist.isNotEmpty) {
//       _currentIndex = 0;
//       await _playCurrentIndex();
//     } else {
//       if(_player.playerState.processingState == ProcessingState.ready){
//         await _player.play();
//       }
//     }
//   }
//
//   @override
//   Future<void> pause() => _player.pause();
//
//   @override
//   Future<void> seek(Duration position) => _player.seek(position);
//
//   @override
//   Future<void> skipToQueueItem(int index) async {
//     if (index < 0 || index >= _playlist.length) return;
//
//     _currentIndex = index;
//     await _playCurrentIndex();
//   }
//
//   @override
//   Future<void> skipToNext() async => _skipToNext();
//
//   Future<void> _skipToNext() async {
//     if (_playlist.isEmpty) return;
//
//     final nextIndex = (_currentIndex + 1) % _playlist.length;
//     _currentIndex = nextIndex;
//     _playCurrentIndex();
//   }
//
//   @override
//   Future<void> skipToPrevious() async {
//     if (_playlist.isEmpty) return;
//
//     final prevIndex = _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
//     _currentIndex = prevIndex;
//     await _playCurrentIndex();
//   }
//
//   @override
//   Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
//     // 1. 无论如何，先更新 AudioService 的状态，让 UI 层知道当前是什么模式
//     playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
//
//     // 2. 控制底层 just_audio 的行为
//     switch (repeatMode) {
//       case AudioServiceRepeatMode.none:
//         _player.setLoopMode(LoopMode.off);
//         break;
//
//       case AudioServiceRepeatMode.group:
//       case AudioServiceRepeatMode.all:
//       // *** 关键修改 ***
//       // 虽然业务逻辑是“列表循环”，但必须告诉 just_audio “不循环”。
//       // 这样歌曲播完才会停止，触发 completed，你的 _listenForPlaybackCompletion 才能工作。
//         _player.setLoopMode(LoopMode.off);
//         break;
//
//       case AudioServiceRepeatMode.one:
//       // 单曲循环可以让 just_audio 自己处理（效率更高，无缝衔接）
//       // 也可以设置为 off 然后自己处理，但用 LoopMode.one 最简单
//         _player.setLoopMode(LoopMode.one);
//         break;
//     }
//   }
//
//   @override
//   Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
//     if (name == 'dispose') {
//       await _player.dispose();
//       super.stop();
//     }
//   }
//
//   @override
//   Future<void> stop() async {
//     await _player.stop();
//     _currentIndex = -1;
//     _isPlaylistPrepared = false;
//     return super.stop();
//   }
//   // 清空播放列表
//   Future<void> clearPlaylist() async {
//     _playlist.clear();
//     _currentIndex = -1;
//     _isPlaylistPrepared = false;
//     queue.add(_playlist);
//   }
// }

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';


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
  final AudioPlayer _player = AudioPlayer();

  final List<MediaItem> _playlist = [];


  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForPositionChanges();
    _listenForCurrentItemChanges(); // 新增：监听当前歌曲索引变化
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
    // 1. 设置音量
    await _player.setVolume(volume);

    await setRepeatMode(repeatMode);
    await setShuffleMode(
        shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

    // 3. 更新本地数据源和通知 UI
    _playlist.clear();
    _playlist.addAll(initialPlaylist);
    queue.add(List.from(_playlist)); // 通知 AudioService/UI 更新列表

    if (_playlist.isEmpty) return;

    // 4. 构建 AudioSource 列表
    final children = _playlist.map(_buildAudioSource).toList();
    // 不再使用try-catch 捕获错误，而是交由errorStream进行监听
    await _player.setAudioSources(
      children,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      shuffleOrder: DefaultShuffleOrder(),
    );
  }
  Future<void> loadPlaylist(
      List<MediaItem> items, {
        int initialIndex = 0,
        Duration? initialPosition,
        bool autoPlay = true,
      }) async {
    // 1. 更新内部列表和 UI
    _playlist.clear();
    _playlist.addAll(items);
    queue.add(List.from(_playlist));

    // 2. 构建 AudioSource
    final children = items.map(_buildAudioSource).toList();

    try {
      // 3. 原子化设置：列表 + 索引 + 进度
      // setAudioSource 会等待资源准备好，不会出现 index out of bounds， 也不会出现进度跳转失败
      await _player.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition ?? Duration.zero,
        shuffleOrder: DefaultShuffleOrder(),
      );
      if (autoPlay) {
        _player.play();
      }
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  /// 将 MediaItem 转换为 AudioSource
  AudioSource _buildAudioSource(MediaItem item) {
    final url = item.extras!['url'] as String;
    final bool isNetwork = url.startsWith('http://') || url.startsWith('https://');
    final uri = isNetwork ? Uri.parse(url) : Uri.file(url);

    return AudioSource.uri(
      uri,
      tag: item, // 关键：把 MediaItem 绑在 tag 上，方便取回
    );
  }

  /// 核心：把当前的 _playlist 转换成 AudioSource 列表并同步给播放器
  Future<void> _updatePlayerSources() async {
    try {
      // 1. 构建 AudioSource 列表
      final sources = _playlist.map(_buildAudioSource).toList();

      // 2. 如果列表为空
      if (sources.isEmpty) {
        await _player.setAudioSources([]);
        return;
      }

      // 3. 记录当前状态，防止刷新列表时导致播放重置
      final currentIndex = _player.currentIndex ?? 0;
      final currentPos = _player.position;

      // 4. 全量设置给播放器
      // 使用 initialIndex 和 initialPosition 尽量保持当前播放状态
      await _player.setAudioSources(
        sources,
        initialIndex: currentIndex < sources.length ? currentIndex : 0,
        initialPosition: currentPos,
        shuffleOrder: DefaultShuffleOrder(),
      );
    } catch (e) {
      debugPrint("Error updating player sources: $e");
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // 1. 业务去重逻辑 (保留你的逻辑)
    if (_playlist.any((item) => item.id == mediaItem.id)) return;

    // 2. 添加到本地列表
    _playlist.add(mediaItem);

    // 3. 通知 AudioService UI 更新
    queue.add(List.from(_playlist));

    // 4. 同步给底层播放器
    await _updatePlayerSources();
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems, {int startIndex = 0}) async {
    final existingIds = _playlist.map((e) => e.id).toSet();
    final toAdd = mediaItems.where((e) => !existingIds.contains(e.id)).toList();

    if (toAdd.isEmpty) return;

    _playlist.addAll(toAdd);
    queue.add(List.from(_playlist));
    await _updatePlayerSources();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);
    queue.add(List.from(_playlist));
    await _player.removeAudioSourceAt(index);
  }

  Future<void> clearPlaylist() async {
    _playlist.clear();
    queue.add([]);
    await _player.setAudioSources([]);
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
  Future<void> skipToNext() => _player.seekToNext(); // 原生跳转，无缝播放

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) _player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    // 1. 更新 UI 状态
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));

    // 2. 设置原生循环模式
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off); // 播完列表自动停止
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all); // 列表循环
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one); // 单曲循环
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    if (shuffleMode == AudioServiceShuffleMode.all) {
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }
  }

  // --- 监听与同步 ---

  /// 关键：监听 just_audio 的索引变化，反向更新 mediaItem
  void _listenForCurrentItemChanges() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _playlist.length) {
        // 1. 获取当前 MediaItem
        final item = _playlist[index];
        // 2. 更新 AudioService 当前媒体
        mediaItem.add(item);
        // 3. 更新播放状态中的 index
        playbackState.add(playbackState.value.copyWith(queueIndex: index));
      }
    });
  }
  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      int currentIndex = _player.currentIndex ?? -1;
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
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
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
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        speed: _player.speed,
      ));
    });
  }

  void _listenForPositionChanges() {
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
    _player.bufferedPositionStream.listen((bufferedPosition) {
      playbackState.add(playbackState.value.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  void _listenErrorPlayState() {
    _player.errorStream.listen((e) {
      KikoenaiLogger().e("${e.message}");
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: "无法加载音频: ${e.message}",
      ));
    });
  }

  Stream<double> get volumeStream => _player.volumeStream;
  double get volume => _player.volume;
  Future<void> setVolume(double v) => _player.setVolume(v);

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'reorderQueue') {
      final int oldIndex = extras!['oldIndex'];
      final int newIndex = extras['newIndex'];

      // 1. 获取当前播放的索引
      int? currentIndex = playbackState.value.queueIndex;
      // 2. 只有在当前有播放索引时才需要计算
      if (currentIndex != null) {
        if (oldIndex == currentIndex) {
          // 情况 A: 拖动的就是当前正在播放的歌曲 -> 索引直接变为新位置
          currentIndex = newIndex;
        } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
          // 情况 B: 把当前播放歌曲 *前面* 的一首歌，拖到了 *后面*
          // 列表里前面的东西少了，当前歌曲的索引需要 -1
          currentIndex--;
        } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
          // 情况 C: 把当前播放歌曲 *后面* 的一首歌，拖到了 *前面*
          // 列表里前面的东西多了，当前歌曲的索引需要 +1
          currentIndex++;
        }
      }

      // 3. 执行列表移动操作
      final currentQueue = queue.value;
      final item = currentQueue.removeAt(oldIndex);
      currentQueue.insert(newIndex, item);
      queue.add(currentQueue);

      // 4. 广播更新后的 playbackState
      playbackState.add(playbackState.value.copyWith(
        queueIndex: currentIndex,
      ));

      await _player.moveAudioSource(oldIndex, newIndex);
    }
    return super.customAction(name, extras);
  }
}