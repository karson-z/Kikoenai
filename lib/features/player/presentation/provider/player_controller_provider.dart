import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/service/lyrics/search_lyrics_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/player/presentation/provider/player_feedback_provider.dart';
import 'package:kikoenai/features/player/presentation/provider/player_lyrics_provider.dart';
import '../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/model/file_node.dart';
import '../../../../core/service/lyrics/match_lyrics_service.dart';
import '../../../../core/storage/hive_key.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../overly-lyrics/data/service/overly_lyrics_sync_service.dart';
import '../../../overly-lyrics/presentation/provider/overly_lyrics_provider.dart';
import '../../data/model/player_state.dart';
import '../../data/model/progress_state.dart';
import '../widget/player_lyrics_mapping_sheet.dart';

final playerControllerProvider =
    NotifierProvider<PlayerController, AppPlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<AppPlayerState> {
  ReceivePort? _overlayReceivePort;

  AudioHandler get _handler => AudioServiceSingleton.instance;

  CacheService get _cacheService => CacheService.instance;

  @override
  AppPlayerState build() {
    _listen();

    Future.microtask(() {
      _loadPlayerState();
    });
    ref.onDispose(() {
      _closeOverlayPort();
    });
    return AppPlayerState();
  }

  /// 从缓存恢复播放器状态
  Future<void> _loadPlayerState() async {
    final savedState = _cacheService.getPlayerState();
    if (savedState == null) return;
    // 1. 恢复播放列表
    final playList = savedState.playlist;
    // 2. 恢复当前索引
    // 加上空判断，防止 crash
    final progress = savedState.progressBarState.current;
    if (savedState.currentTrack != null) {
      final currentIndex = playList.indexWhere(
        (item) => item.id == savedState.currentTrack!.id,
      );
      // await (_handler as MyAudioHandler).skipToQueueItem(currentIndex,position: progress,play: false);
      //  // if (currentIndex >= 0 && _handler is MyAudioHandler) {
      //  //   await (_handler as MyAudioHandler).setCurrentIndex(currentIndex);
      //  // }
      await (_handler as MyAudioHandler).initPlayback(
        initialPlaylist: playList,
        initialIndex: currentIndex,
        initialPosition: progress,
        volume: savedState.volume,
        repeatMode: savedState.repeatMode,
        shuffleEnabled: savedState.shuffleEnabled,
      );
    }
    state = state.copyWith(subtitleMapping: savedState.subtitleMapping);
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
    // 3. 解析 WorkID
    String? workId;
    try {
      final workDataStr = item.extras?['workData'];
      if (workDataStr != null) {
        // 兼容 String 和 Map 两种格式
        final workJson =
            workDataStr is String ? jsonDecode(workDataStr) : workDataStr;
        workId = workJson['id']?.toString();
      }
    } catch (e) {
      debugPrint("埋点解析 WorkID 失败: $e");
    }

    // 4. 通知 Provider
    if (workId != null && workId.isNotEmpty) {
      ref.read(playbackTrackerProvider.notifier).updatePlaybackStatus(
            workId: workId,
            isPlaying: finalIsPlaying,
          );
    }
  }

// 4. 新增清理端口的方法
  void _closeOverlayPort() {
    IsolateNameServer.removePortNameMapping('overlay_playback_port');
    _overlayReceivePort?.close();
    _overlayReceivePort = null;
  }

  // 5. 重写 _listenToOverlayCommands 方法
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
          case 'CMD_PLAY':
            play();
            break;
          case 'CMD_PAUSE':
            pause();
            break;
          case 'CMD_NEXT':
            next();
            break;
          case 'CMD_PREVIOUS':
            previous();
            break;
          case 'CMD_CLOSE_OVERLAY':
          // 由主应用统一执行隐藏，这会同时销毁窗口并休眠字幕同步服务
            lyricsNotifier.hide(isUserAction: true);
            break;
          case 'CMD_TOGGLE_LOCK':
            final isLocked = ref.read(lyricsControllerProvider).isLocked;
            lyricsNotifier.updateLockState(!isLocked);
            break;
          case 'CMD_COLOR':
            final colorValue = payload?['color'] as int?;
            if (colorValue != null) {
              setting.put(StorageKeys.overlayLyricsFontColor, colorValue);
            }
            break;
          case 'CMD_SAVE_POSITION':
            final x = payload?['x'] as double?;
            final y = payload?['y'] as double?;
            if (x != null && y != null) {
              setting.put(StorageKeys.overlayLyricsPositionX, x);
              setting.put(StorageKeys.overlayLyricsPositionY, y);
            }
            break;
          case 'CMD_UPDATE_FONT_SIZE':
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
        _saveHistory();
      }
    });
    // 低频流：处理播放与暂停状态切换
    _handler.playbackState
        .map((p) => p.playing)
        .distinct()
        .listen((isPlaying) {

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
      _updateSubtitleState(item);
      if (state.currentTrack?.id != item?.id) {
        state = state.copyWith(
          currentTrack: item,
        );
      }
      _updateSkipInfo();
      if (state.currentTrack != null) {
        _saveState();
        _saveHistory();
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

    if (playlist.isEmpty || current == null) {
      state = state.copyWith(isFirst: true, isLast: true);
      return;
    }

    final i = playlist.indexOf(current);
    state = state.copyWith(
      isFirst: i <= 0,
      isLast: i >= playlist.length - 1,
    );
  }

  // 保存播放器状态
  void _saveState() {
    _cacheService.savePlayerState(state);
  }

  // 保存播放历史
  void _saveHistory() {
    final currentItem = state.currentTrack;
    if (currentItem == null) return;

    final workData = currentItem.extras?['workData'];
    if (workData == null) return;

    try {
      final workJson = workData is String ? jsonDecode(workData) : workData;
      final currentWork = Work.fromJson(workJson);

      if (currentWork.id == null) return;

      final history = HistoryEntry(
        work: currentWork,
        lastTrackId: currentItem.id,
        currentTrackTitle: currentItem.title,
        lastProgressMs: state.progressBarState.current.inMilliseconds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _cacheService.addToHistory(history);
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }

  // --- 控制方法 ---
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

  Future<void> toggleShuffle() async {
    final enabled = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: enabled);
    await _handler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
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

  // 私有方法，交给监听器触发
  void _updateSubtitleState(MediaItem? currentItem) async {
    // 1. 基础空值处理
    if (currentItem == null) {
      state = state.copyWith(currentTrack: null);
      return;
    }
    if (currentItem.id == state.currentTrack?.id) return;

    // 2. 获取 ID 进行比对
    final int? lastWorkId = _getWorkIdFromItem(state.currentTrack);
    final int? newWorkId = _getWorkIdFromItem(currentItem);
    List<FileNode> targetSubtitleList = [];
    bool isWorkChanged = newWorkId != lastWorkId;

    if (isWorkChanged && newWorkId != null) {
      debugPrint(
          "检测到作品变化或列表为空 (Old: $lastWorkId -> New: $newWorkId)，开始查找字幕...");

      targetSubtitleList = await SearchLyricsService.findLyrics(newWorkId, ref);

      // 过滤播放列表，仅保留当前作品的音频
      final currentWorkPlaylist = state.playlist
          .where((item) => _getWorkIdFromItem(item) == newWorkId)
          .toList();

      // 处理过滤后的播放列表数据
      final playListProcessed =
          LyricsDataProcess.batchPlayListProcess(currentWorkPlaylist);

      // 处理字幕数据
      final lyricListProcessed =
          LyricsDataProcess.batchLyricsProcess(targetSubtitleList);

      // 匹配字幕并处理手动匹配回调
      final matches = MatchLyrics.match(playListProcessed, lyricListProcessed,
          onShowManualMatchDialog:
              (playlist, availableSubtitles, currentMapping) async {
        final manualResult = await LyricsMappingSheet.show(
          playlist: playlist,
          initialMapping: currentMapping,
          availableSubtitles: availableSubtitles,
        );
        if (manualResult != null) {
          final validManualMapping = <String, FileNode>{};
          manualResult.forEach((key, value) {
            if (value != null) {
              validManualMapping[key] = value;
            } else {
              AppStorage.lyricMatchBox.delete(key);
            }
          });

          MatchLyrics.persistMatchResults(validManualMapping);

          state = state.copyWith(subtitleMapping: validManualMapping);
        }
      });

      state = state.copyWith(
          lyricsList: targetSubtitleList, subtitleMapping: matches);

      if (kDebugMode) {
        if (matches.isEmpty) {
          KikoenaiLogger().i('本次扫描未匹配到任何字幕。');
        } else {
          final buffer = StringBuffer();
          buffer.writeln('匹配成功报告 (共 ${matches.length} 条):');

          // 创建一个临时 Map 用于通过 Hash 反查音频标题
          final audioTitleMap = {
            for (var node in playListProcessed) node.id: node.title
          };

          matches.forEach((audioHash, subtitleNode) {
            final audioTitle = audioTitleMap[audioHash] ?? "Hash: $audioHash";
            buffer.writeln('  🎵 $audioTitle');
            buffer.writeln('   └── 📝 ${subtitleNode.title}');
          });

          KikoenaiLogger().i(buffer.toString());
        }
      }
    }
  }

  Future<void> addSingleInQueue(FileNode node, Work work) async {
    final mediaItem = _fileNodeToMediaItem(node, work);
    await add(mediaItem);
  }

  Future<void> handleFileTap(FileNode node, List<FileNode> currentNodes,
      {HistoryEntry? history, Work? work}) async {
    if (node.isAudio || node.isVideo) {
      final audioFiles =
          currentNodes.where((n) => n.isAudio || n.isVideo).toList();
      final mediaList = audioFiles.map((n) {
        return _fileNodeToMediaItem(n, work ?? Work());
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
          autoPlay: true, // 点击通常意味着想直接播放
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

  Future<HistoryEntry?> checkHistoryForWork(Work work) async {
    final historyList = CacheService.instance.getHistoryList();
    try {
      final history = historyList.firstWhere(
        (h) => h.work.id == work.id,
      );
      return history;
    } catch (e) {
      debugPrint('checkHistoryForWork: 当前作品暂无历史记录');
    }
    return null;
  }

  Map<String, dynamic>? findTrackParentAndIndex(
      List<FileNode> nodes, String trackId) {
    for (var node in nodes) {
      if (node.isAudio && node.hash.toString() == trackId) {
        // 当前节点就在根层级
        return {'parentList': nodes, 'index': nodes.indexOf(node)};
      }
      if (node.children != null && node.children!.isNotEmpty) {
        final result = findTrackParentAndIndex(node.children!, trackId);
        if (result != null) return result;
      }
    }
    return null; // 未找到
  }

  Future<void> restoreHistory(
      List<FileNode> nodes, Work work, HistoryEntry history) async {
    if (history.lastTrackId == null) return;

    final found = findTrackParentAndIndex(nodes, history.lastTrackId!);
    if (found == null) return;

    final parentList = found['parentList'] as List<FileNode>;
    final index = found['index'] as int;
    final currentNode = parentList[index];
    await handleFileTap(currentNode, parentList, history: history, work: work);
  }

  Future<void> removeMediaItemInQueue(int index) async {
    await _handler.removeQueueItemAt(index);
    if (state.playlist.isEmpty) {
      state = AppPlayerState();
    }
    _saveState();
  }

  Future<void> addMultiInQueue(List<FileNode> nodes, Work work) async {
    final mediaList = nodes.map((node) {
      return _fileNodeToMediaItem(node, work);
    }).toList();
    await addAll(mediaList);
  }

  Future<void> cyclePlayMode() async {
    // 1. 如果当前是随机模式
    if (state.shuffleEnabled) {
      // 点击后：关闭随机 -> 切换到列表循环 (回到最基础的状态)
      await toggleShuffle(); // 关闭随机
      await setRepeat(AudioServiceRepeatMode.all);
      return;
    }

    // 2. 如果当前不是随机模式，检查循环状态
    switch (state.repeatMode) {
      case AudioServiceRepeatMode.all:
        // 当前是列表循环 -> 切换到单曲循环
        await setRepeat(AudioServiceRepeatMode.one);
        break;

      case AudioServiceRepeatMode.one:
        // 当前是单曲循环 -> 切换到不循环 (新增逻辑)
        await setRepeat(AudioServiceRepeatMode.none);
        break;

      case AudioServiceRepeatMode.none:
        // 当前是不循环 -> 切换到随机播放
        // 开启随机时，通常将循环模式设为 all (意味着随机播放整个列表直到手动停止，或者你想随机播完一轮停止也可以设为 none)
        await setRepeat(AudioServiceRepeatMode.all);
        await toggleShuffle();
        break;

      case AudioServiceRepeatMode.group:
        await setRepeat(AudioServiceRepeatMode.all);
        break;
    }
  }

  MediaItem _fileNodeToMediaItem(FileNode node, Work work) {
    String? imagePath;

    final url = node.mediaStreamUrl ?? '';
    final isVideo =
        FileExtensions.video.any((ext) => url.toLowerCase().endsWith(ext)) ||
            node.isVideo == true;

    return MediaItem(
      id: node.hash.toString(),
      album: node.workTitle,
      title: node.title,
      artist: work.vas == null ? node.artist : OtherUtil.joinVAs(work.vas),
      artUri: work.mainCoverUrl != null ? Uri.parse(work.mainCoverUrl!) : null,
      extras: {
        'url': url,
        'mainCoverUrl': work.mainCoverUrl ?? imagePath,
        'samCorverUrl': work.samCoverUrl ?? imagePath,
        'workData': jsonEncode(work),
        'isVideo': isVideo, // 【新增】将视频标记存入 extras
      },
    );
  }

  int? _getWorkIdFromItem(MediaItem? item) {
    if (item == null) return null;
    final workData = item.extras?['workData'];
    if (workData == null) return null;
    try {
      // 兼容 JSON String 和 Map
      final workJson = workData is String ? jsonDecode(workData) : workData;
      return workJson['id'];
    } catch (e) {
      debugPrint("解析 WorkID 异常: $e");
      return null;
    }
  }
}

class AudioOnlyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // 初始状态：默认不开启仅音频模式 (画面正常解码)
    return false;
  }

  /// 暴露给 UI 调用的唯一方法，屏蔽底层通信细节
  Future<void> toggleMode(bool isAudioOnly) async {
    // 1. 更新内部状态，触发 UI 重绘
    state = isAudioOnly;

    // 2. 状态变更的副作用：统一下发指令给音频服务
    // 仅音频 (isAudioOnly = true) 时，关闭视频解码 (enable = false)
    await AudioServiceSingleton.instance.customAction(
      'toggleVideoDecoding',
      {'enable': !isAudioOnly},
    );
  }
}

// 暴露 Provider
final audioOnlyModeProvider = NotifierProvider<AudioOnlyModeNotifier, bool>(() {
  return AudioOnlyModeNotifier();
});
