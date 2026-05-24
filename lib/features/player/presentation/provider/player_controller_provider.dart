import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/history/data/model/history_entry.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/history/presentation/provider/history_controller_provider.dart';
import 'package:kikoenai/features/player/presentation/provider/player_feedback_provider.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../core/constants/app_player.dart';
import '../../../../core/service/audio/audio_extension.dart';
import '../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/model/file_node.dart';
import '../../../../core/service/player/player_service.dart';
import '../../../../core/storage/hive_key.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/utils/window/display_util.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../core/widgets/layout/provider/main_scaffold_provider.dart';
import '../../../overly-lyrics/presentation/provider/overly_lyrics_provider.dart';
import '../../data/model/player_state.dart';
import '../../data/model/progress_state.dart';

final playerControllerProvider =
    NotifierProvider<PlayerController, AppPlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<AppPlayerState> {
  ReceivePort? _overlayReceivePort;

  Timer? _controlsHideTimer;

  AudioHandler get _handler => AudioServiceSingleton.instance;

  Player get _player => PlayerService.instance.player;

  CacheService get _cacheService => CacheService.instance;

  AppLifecycleListener? _lifecycleListener;

  @override
  AppPlayerState build() {
    _listen();

    _listenToPlayer();

    // 1. 监听应用生命周期：退出、退到后台、被强杀时，保存当前进度
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _saveCurrentHistory(),
      onHide: () => _saveCurrentHistory(),
      onDetach: () => _saveCurrentHistory(),
    );

    Future.microtask(() {
      _loadPlayerState();
    });
    startControlsHideTimer();

    ref.onDispose(() {
      // 2. Controller 销毁前最后保存一次
      _saveCurrentHistory();

      _closeOverlayPort();
      _controlsHideTimer?.cancel();
      _lifecycleListener?.dispose(); // 销毁生命周期监听器
      stop();
    });
    return const AppPlayerState();
  }

  void startControlsHideTimer() {
    cancelControlsHideTimer();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      state = state.copyWith(isVideoControlsVisible: false);
    });
  }

  void cancelControlsHideTimer() {
    _controlsHideTimer?.cancel();
  }

  // 翻转控制面板显隐状态
  void toggleControlsVisibility() {
    final isVisible = !state.isVideoControlsVisible;
    state = state.copyWith(isVideoControlsVisible: isVisible);
    if (isVisible) {
      startControlsHideTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void showControlsAndResetTimer() {
    if (!state.isVideoControlsVisible) {
      state = state.copyWith(isVideoControlsVisible: true);
    }
    startControlsHideTimer();
  }

  /// 从缓存恢复播放器状态
  Future<void> _loadPlayerState() async {
    final savedState = _cacheService.getPlayerState();
    if (savedState == null) return;

    // 1. 恢复播放列表
    final playList = savedState.playlist;

    // 2. 恢复当前索引
    final progress = savedState.progressBarState.current;
    if (savedState.currentTrack != null) {
      final currentIndex = playList.indexWhere(
        (item) => item.id == savedState.currentTrack!.id,
      );
      await (_handler as MyAudioHandler).initPlayback(
        initialPlaylist: playList,
        initialIndex: currentIndex,
        initialPosition: progress,
        volume: savedState.volume,
        repeatMode: savedState.repeatMode,
        shuffleEnabled: savedState.shuffleEnabled,
      );
    }

    // 恢复仅音频模式到底层播放引擎
    if (savedState.isAudioOnly) {
      _handler.customAction('toggleVideoDecoding', {
        'enable': !savedState.isAudioOnly,
      });
    }

    state = state.copyWith(isAudioOnly: savedState.isAudioOnly);
  }

  void _updateTrackerStatus({
    bool? isPlaying,
    bool isCompleted = false,
    MediaItem? mediaItem,
  }) {
    final item = mediaItem ?? state.currentTrack;

    final finalIsPlaying = isCompleted ? false : (isPlaying ?? state.playing);

    if (item == null) {
      return;
    }
    final workId = item.workData?.id.toString();

    // 4. 通知 Provider
    if (workId != null && workId.isNotEmpty) {
      ref
          .read(playbackTrackerProvider.notifier)
          .updatePlaybackStatus(workId: workId, isPlaying: finalIsPlaying);
    }
  }

  void _closeOverlayPort() {
    IsolateNameServer.removePortNameMapping('overlay_playback_port');
    _overlayReceivePort?.close();
    _overlayReceivePort = null;
  }

  void _listenToPlayer() {
    _player.stream.videoParams.listen((params) {
      final width = params.dw ?? params.w ?? 0;
      final height = params.dh ?? params.h ?? 0;
      final rotate = params.rotate ?? 0;

      if (width > 0 && height > 0) {
        if (state.videoWidth != width ||
            state.videoHeight != height ||
            state.videoRotate != rotate) {
          state = state.copyWith(
            videoWidth: width,
            videoHeight: height,
            videoRotate: rotate,
          );
        }
      }
    });
    _player.stream.tracks.listen((tracks) {
      state = state.copyWith(
        availableAudioTracks: tracks.audio,
        availableSubtitleTracks: tracks.subtitle,
      );
    });
    _player.stream.audioParams.listen((params) {
      state = state.copyWith(audioParams: params.toString());
    });
  }

  void _listenToOverlayCommands() {
    debugPrint('AudioController: 准备连接悬浮窗事件总线 (IsolateNameServer)...');

    // 清理可能残留的同名映射
    IsolateNameServer.removePortNameMapping('overlay_playback_port');

    // 实例化接收端口
    _overlayReceivePort = ReceivePort();

    // 在全局命名空间注册 SendPort
    final success = IsolateNameServer.registerPortWithName(
      _overlayReceivePort!.sendPort,
      'overlay_playback_port',
    );

    if (success) {
      debugPrint('AudioController: 悬浮窗播控端口 [overlay_playback_port] 注册成功');

      // 监听内存通道传入的数据
      _overlayReceivePort!.listen((message) {
        debugPrint('AudioController: 内存通道捕获到指令 -> $message');
        String? action;
        Map<dynamic, dynamic>? payload;

        if (message is Map) {
          action = message['action'] as String?;
          payload = message['payload'] as Map<dynamic, dynamic>?;
        } else if (message is String) {
          action = message;
        }
        if (action == null) return;
        final lyricsNotifier = ref.read(lyricsControllerProvider.notifier);
        final setting = AppStorage.settingsBox;

        switch (action) {
          case PlayerConstants.play:
            play();
            break;
          case PlayerConstants.pause:
            pause();
            break;
          case PlayerConstants.next:
            next();
            break;
          case PlayerConstants.previous:
            previous();
            break;
          case PlayerConstants.closeOverlay:
            lyricsNotifier.hide(isUserAction: true);
            break;
          case PlayerConstants.toggleLock:
            final isLocked = ref.read(lyricsControllerProvider).isLocked;
            lyricsNotifier.updateLockState(!isLocked);
            break;
          case PlayerConstants.color:
            final colorValue = payload?['color'] as int?;
            if (colorValue != null) {
              setting.put(StorageKeys.overlayLyricsFontColor, colorValue);
            }
            break;
          case PlayerConstants.savePosition:
            final x = payload?['x'] as double?;
            final y = payload?['y'] as double?;
            if (x != null && y != null) {
              setting.put(StorageKeys.overlayLyricsPositionX, x);
              setting.put(StorageKeys.overlayLyricsPositionY, y);
            }
            break;
          case PlayerConstants.updateFontSize:
            final size = payload?['size'] as double?;
            if (size != null) {
              setting.put(StorageKeys.overlayLyricsFontSize, size);
            }
            break;
        }
      });
    } else {
      debugPrint('AudioController: ⚠ 悬浮窗播控端口注册失败，名称可能被占用。');
    }
  }

  /// 监听播放状态变化
  void _listen() {
    // 播放状态 & 缓冲状态
    _handler.playbackState.listen((p) {
      final newProgress = ProgressBarState(
        current: p.position,
        buffered: p.bufferedPosition,
        total: _handler.mediaItem.value?.duration ?? Duration.zero,
      );

      final isCompleted = p.processingState == AudioProcessingState.completed;

      state = state.copyWith(
        loading: p.processingState == AudioProcessingState.loading ||
            p.processingState == AudioProcessingState.buffering,
        progressBarState: newProgress,
      );

      if (isCompleted) {
        _updateTrackerStatus(isPlaying: false, isCompleted: true);
      }

      if (state.currentTrack != null) {
        _saveState();
      }
    });

    // 低频流：处理播放与暂停状态切换
    _handler.playbackState.map((p) => p.playing).distinct().listen((isPlaying) {
      state = state.copyWith(playing: isPlaying);

      _updateTrackerStatus(isPlaying: isPlaying, isCompleted: false);

      ref.read(subtitleManagerProvider).syncBusinessState({
        'isPlaying': isPlaying,
      });

      if (state.currentTrack != null) {
        _saveState();
      }
    });

    // 当前播放曲目
    _handler.mediaItem.listen((item) {
      final currentItem = state.currentTrack;

      if (currentItem != null && currentItem.id != item?.id) {
        _saveCurrentHistory();
      }

      if (currentItem?.id != item?.id) {
        state = state.copyWith(currentTrack: item);
      }

      _updateSkipInfo();

      if (state.currentTrack != null) {
        _saveState();
      }
      _updateTrackerStatus(mediaItem: item, isPlaying: state.playing);
    });

    // 播放列表变化
    _handler.queue.listen((queue) {
      state = state.copyWith(playlist: queue);
      _updateSkipInfo();
      if (state.currentTrack != null) {
        _saveState();
      }
    });

    // 音量变化
    if (_handler is MyAudioHandler) {
      (_handler as MyAudioHandler).volumeStream.listen((v) {
        state = state.copyWith(volume: v);
        if (state.currentTrack != null) {
          _saveState();
        }
      });
    }
    _listenToOverlayCommands();
  }

  void _updateSkipInfo() {
    final playlist = state.playlist;
    final current = _handler.mediaItem.value;

    final isLooping = state.repeatMode != AudioServiceRepeatMode.none;

    if (playlist.isEmpty || current == null) {
      state = state.copyWith(isFirst: true, isLast: true);
      return;
    }

    final i = playlist.indexOf(current);

    state = state.copyWith(
      isFirst: isLooping ? false : i <= 0,
      isLast: isLooping ? false : i >= playlist.length - 1,
    );
  }

  // 保存播放器状态 (队列、模式配置等)
  void _saveState() {
    _cacheService.savePlayerState(state);
  }

  void _saveCurrentHistory() {
    final currentItem = state.currentTrack;

    if (currentItem == null) return;

    final historyType = HistoryEntryType.values.firstWhere(
      (e) => e.name == currentItem.extras?['historyType'],
      orElse: () => HistoryEntryType.work,
    );

    final currentWork = currentItem.workData;
    final currentProgressMs = state.progressBarState.current.inMilliseconds;


    try {
      final history = HistoryEntry(
        work: currentWork,
        lastPlayTrack: currentItem,
        lastProgressMs: currentProgressMs,
        lastPlayTime: DateTime.now().millisecondsSinceEpoch,
        playlist: state.playlist,
        historyType: historyType,
      );

      ref.read(historyControllerProvider.notifier).upsert(history);

      debugPrint('历史记录持久化完成: [${currentItem.title}] -> $currentProgressMs ms');
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }


  Future<void> play() async => _handler.play();

  Future<void> pause() async => _handler.pause();

  Future<void> stop() async => _handler.stop();

  Future<void> seek(Duration d) async => _handler.seek(d);

  Future<void> next() async => _handler.skipToNext();

  Future<void> previous() async => _handler.skipToPrevious();

  Future<void> setVolume(double v) async {
    if (_handler is MyAudioHandler) {
      await (_handler as MyAudioHandler).setVolume(v);
    }
  }

  Future<void> loadExternalSubtitle(
    String uri, {
    String? title,
    String? language,
  }) async {
    final externalTrack = SubtitleTrack.uri(
      uri,
      title: title ?? 'External Subtitle',
      language: language,
    );

    state = state.copyWith(
      externalSubtitleTracks: [...state.externalSubtitleTracks, externalTrack],
    );

    await setSubtitleTrack(externalTrack);
  }

  Future<void> loadExternalAudioTrack(
    String uri, {
    String? title,
    String? language,
  }) async {
    final externalTrack = AudioTrack.uri(
      uri,
      title: title ?? 'External Audio',
      language: language,
    );

    state = state.copyWith(
      externalAudioTracks: [...state.externalAudioTracks, externalTrack],
    );

    await setAudioTrack(externalTrack);
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    try {
      await _player.setAudioTrack(track);
    } catch (e) {
      debugPrint("切换音频轨道失败: $e");
    }
  }

  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    try {
      await _player.setSubtitleTrack(track);
    } catch (e) {
      debugPrint("切换字幕轨道失败: $e");
    }
  }

  /// 切换纯音频模式
  Future<void> toggleAudioOnlyMode(bool isAudioOnly) async {
    state = state.copyWith(isAudioOnly: isAudioOnly);
    await _handler.customAction('toggleVideoDecoding', {
      'enable': !isAudioOnly,
    });
    _saveState();
  }

  Future<void> toggleShuffle() async {
    final enabled = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: enabled);
    await _handler.setShuffleMode(
      enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    _saveState();
  }

  Future<void> setRepeat(AudioServiceRepeatMode mode) async {
    state = state.copyWith(repeatMode: mode);
    await _handler.setRepeatMode(mode);
    _saveState();
  }

  void replacePlaylist(int oldIndex, int newIndex) async {
    await _handler.customAction('reorderQueue', {
      'oldIndex': oldIndex,
      'newIndex': newIndex,
    });
  }

  Future<void> add(MediaItem item) async {
    await _handler.addQueueItem(item);
  }

  Future<void> addAll(List<MediaItem> items) async {
    await _handler.addQueueItems(items);
  }

  Future<void> skipTo(int index) async {
    await _handler.skipToQueueItem(index);
  }

  Future<void> clear() async {
    await (_handler as MyAudioHandler).clearPlaylist();
  }

  Future<void> addSingleInQueue(
    FileNode node,
    Work work, {
    HistoryEntryType historyType = HistoryEntryType.work,
  }) async {
    final mediaItem =
        _fileNodeToMediaItem(node, work, historyType: historyType);
    await add(mediaItem);
  }

  Future<void> handleFileTap(
    FileNode node,
    List<FileNode> currentNodes, {
    HistoryEntry? history,
    Work? work,
    HistoryEntryType historyType = HistoryEntryType.work,
  }) async {
    if (node.isAudio || node.isVideo) {
      final audioFiles =
          currentNodes.where((n) => n.isAudio || n.isVideo).toList();
      final mediaList = audioFiles.map((n) {
        return _fileNodeToMediaItem(n, work, historyType: historyType);
      }).toList();

      // 2. 计算目标索引
      final audioTapIndex = audioFiles.indexOf(node);

      // 3. 计算目标进度
      Duration startPosition = Duration.zero;
      if (history != null && history.lastProgressMs != null) {
        startPosition = Duration(milliseconds: history.lastProgressMs!);
      }
      if (_handler is MyAudioHandler) {
        await (_handler as MyAudioHandler).loadPlaylist(
          mediaList,
          initialIndex: audioTapIndex,
          initialPosition: startPosition,
          autoPlay: true,
        );
      } else {
        await clear();
        await addAll(mediaList);
        await skipTo(audioTapIndex);
        if (startPosition > Duration.zero) {
          await seek(startPosition);
        }
      }
    }
  }

  Future<void> restoreHistory(
    HistoryEntry history,
  ) async {
    if (history.historyType.name == HistoryEntryType.singleWork.name) {
      await _restoreSingleWorkHistory(history);
      return;
    }

    final savedPlaylist = history.playlist;
    if (savedPlaylist != null && savedPlaylist.isNotEmpty) {
      final initialIndex = savedPlaylist.indexWhere(
        (item) => item.id == history.lastPlayTrack.id,
      );
      final safeIndex = initialIndex < 0 ? 0 : initialIndex;
      final startPosition = history.lastProgressMs == null
          ? Duration.zero
          : Duration(milliseconds: history.lastProgressMs!);

      if (_handler is MyAudioHandler) {
        await (_handler as MyAudioHandler).loadPlaylist(
          savedPlaylist,
          initialIndex: safeIndex,
          initialPosition: startPosition,
          autoPlay: true,
        );
      } else {
        await clear();
        await addAll(savedPlaylist);
        await skipTo(safeIndex);
        if (startPosition > Duration.zero) {
          await seek(startPosition);
        }
      }
      return;
    }
  }

  Future<void> _restoreSingleWorkHistory(HistoryEntry history) async {
    final startPosition = history.lastProgressMs == null
        ? Duration.zero
        : Duration(milliseconds: history.lastProgressMs!);

    if (_handler is MyAudioHandler) {
      await (_handler as MyAudioHandler).loadPlaylist(
        [history.lastPlayTrack],
        initialPosition: startPosition,
        autoPlay: true,
      );
    } else {
      await clear();
      await add(history.lastPlayTrack);
      if (startPosition > Duration.zero) {
        await seek(startPosition);
      }
      await play();
    }
  }

  Future<void> removeMediaItemInQueue(int index) async {
    await _handler.removeQueueItemAt(index);
    if (state.playlist.isEmpty) {
      state = const AppPlayerState();
    }
    _saveState();
  }

  Future<void> addMultiInQueue(
    List<FileNode> nodes,
    Work work, {
    HistoryEntryType historyType = HistoryEntryType.work,
  }) async {
    try {
      final mediaList = nodes.map((node) {
        return _fileNodeToMediaItem(node, work, historyType: historyType);
      }).toList();
      await addAll(mediaList);
      KikoenaiToast.success("已加入播放队列");
    } catch (e) {
      KikoenaiLogger().e("加入播放队列失败");
    }
  }

  Future<void> toggleVideoFullScreen() async {
    final currentIsFull = ref.read(mainScaffoldProvider).isFullScreen;
    final targetIsFull = !currentIsFull;

    ref.read(mainScaffoldProvider.notifier).setFullScreen(targetIsFull);

    if (targetIsFull) {
      debugPrint(
        'currentPortrait: ${state.isVideoPortrait} dw: ${state.videoWidth} dh: ${state.videoHeight} rotate: ${state.videoRotate}',
      );
      await DisplayUtils.enterFullScreen(state.isVideoPortrait);
    } else {
      await DisplayUtils.exitFullScreen();
    }
  }

  Future<void> cyclePlayMode() async {
    if (state.shuffleEnabled) {
      await toggleShuffle();
      await setRepeat(AudioServiceRepeatMode.all);
      return;
    }

    switch (state.repeatMode) {
      case AudioServiceRepeatMode.all:
        await setRepeat(AudioServiceRepeatMode.one);
        break;

      case AudioServiceRepeatMode.one:
        await setRepeat(AudioServiceRepeatMode.none);
        break;

      case AudioServiceRepeatMode.none:
        await setRepeat(AudioServiceRepeatMode.all);
        await toggleShuffle();
        break;

      case AudioServiceRepeatMode.group:
        await setRepeat(AudioServiceRepeatMode.all);
        break;
    }
  }

  MediaItem _fileNodeToMediaItem(
    FileNode node,
    Work? work, {
    required HistoryEntryType historyType,
  }) {
    String? imagePath;

    final url = node.mediaStreamUrl ?? '';
    final isVideo =
        FileExtensions.video.any((ext) => url.toLowerCase().endsWith(ext)) ||
            node.isVideo == true;

    return MediaItem(
      id: node.keyId,
      album: node.workTitle,
      title: node.title,
      artist: work?.vas == null ? node.artist : OtherUtil.joinVAs(work?.vas),
      artUri:
          work?.mainCoverUrl != null ? Uri.parse(work!.mainCoverUrl!) : null,
      extras: {
        'workId': work?.id,
        'url': url,
        'mainCoverUrl': work?.mainCoverUrl ?? imagePath,
        'samCorverUrl': work?.samCoverUrl ?? imagePath,
        'workData': work == null ? null : jsonEncode(work),
        'historyType': historyType.name,
        'isVideo': isVideo,
      },
    );
  }
}
