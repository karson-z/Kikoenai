import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/album/data/model/work.dart';


import '../../../../features/album/data/model/file_node.dart';
import '../../../service/audio_service.dart';
import '../state/player_state.dart';
import '../state/progress_state.dart';

final playerControllerProvider = NotifierProvider.autoDispose<PlayerController, AppPlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<AppPlayerState> {
  late final AudioHandler handler;

  @override
  AppPlayerState build() {
    handler = ref.read(audioHandlerFutureProvider);
    _listen();
    _loadPlayerState();
    return AppPlayerState();
  }
  /// 从缓存恢复播放器状态
  void _loadPlayerState() async {
    final cacheService = CacheService.instance;
    final savedState = await cacheService.getPlayerState();
    if (savedState == null) return;
    // 1. 恢复播放列表
    final playList = savedState.playlist;
    if (playList.isNotEmpty) {
      await handler.addQueueItems(playList);
    }
    // 2. 恢复当前索引
    final currentIndex = playList.indexWhere(
          (item) => item.id == savedState.currentTrack?.id,
    );
    (handler as MyAudioHandler).setCurrentIndex(currentIndex >= 0 ? currentIndex : 0);

    // 3. 恢复播放进度
    final progress = savedState.progressBarState.current;
    if (progress > Duration.zero) {
      await handler.seek(progress);
    }

    // 4. 恢复音量
    if (handler is MyAudioHandler) {
      await (handler as MyAudioHandler).setVolume(savedState.volume);
    }

    // 5. 恢复循环模式
    await handler.setRepeatMode(savedState.repeatMode);

    // 6. 恢复随机模式
    await handler.setShuffleMode(
      savedState.shuffleEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  /// 监听播放状态变化
  void _listen() {
    // 播放状态 & 缓冲状态
    handler.playbackState.listen((p) {
      final newProgress = ProgressBarState(
        current: p.position,
        buffered: p.bufferedPosition,
        total: handler.mediaItem.value?.duration ?? Duration.zero,
      );
      state = state.copyWith(
        playing: p.playing,
        loading: p.processingState == AudioProcessingState.loading ||
            p.processingState == AudioProcessingState.buffering,
        progressBarState: newProgress,
      );
      if(state.currentTrack != null){
        _saveState();
        _saveHistory();
      }
    });
    // 当前播放曲目
    handler.mediaItem.listen((item) {
      state = state.copyWith(currentTrack: item);
      _updateSkipInfo();

      if(state.currentTrack != null){
        _saveState();
        _saveHistory();
      }
    });

    // 播放列表变化
    handler.queue.listen((queue) {
      state = state.copyWith(playlist: queue);
      _updateSkipInfo();
      if(state.currentTrack != null){
        _saveState();
      }
    });

    // 音量变化
    if (handler is MyAudioHandler) {
      (handler as MyAudioHandler).volumeStream.listen((v) {
        state = state.copyWith(volume: v);
        if(state.currentTrack != null){
          _saveState();
        }
      });
    }
  }

  void _updateSkipInfo() {
    final playlist = state.playlist;
    final current = handler.mediaItem.value;

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

  void _saveState() {
    CacheService.instance.savePlayerState(state);
  }
  void _saveHistory() {
    final currentItem = state.currentTrack;
    if (currentItem == null) return;

    // 从 extras 中尝试获取 work 数据
    final workData = currentItem.extras?['workData'];
    if (workData == null) return;

    try {

      final workJson = jsonDecode(workData);
      final currentWork = Work.fromJson(workJson);
      final history = HistoryEntry(
        work: currentWork, // 使用解析出来的 work
        lastTrackId: currentItem.id,
        currentTrackTitle: currentItem.title,
        lastProgressMs: state.progressBarState.current.inMilliseconds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      CacheService.instance.saveOrUpdateHistory(history);
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }

  // --- 控制方法 ---
  Future<void> play() async => handler.play();
  Future<void> pause() async => handler.pause();
  Future<void> stop() async => handler.stop();
  Future<void> seek(Duration d) async => handler.seek(d);
  Future<void> next() async => handler.skipToNext();
  Future<void> previous() async => handler.skipToPrevious();

  Future<void> setVolume(double v) async {
    if (handler is MyAudioHandler) {
      await (handler as MyAudioHandler).setVolume(v);
    }
  }

  Future<void> toggleShuffle() async {
    final enabled = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: enabled);
    await handler.setShuffleMode(enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    _saveState();
  }

  Future<void> setRepeat(AudioServiceRepeatMode mode) async {
    state = state.copyWith(repeatMode: mode);
    await handler.setRepeatMode(mode);
    _saveState();
  }
  void replacePlaylist(List<MediaItem> newList) {
    handler.updateQueue(newList);
  }
  Future<void> add(MediaItem item) async {
    await handler.addQueueItem(item);
  }

  Future<void> addAll(List<MediaItem> items) async {
    await handler.addQueueItems(items);
  }

  Future<void> skipTo(int index) async {
    await handler.skipToQueueItem(index);
  }

  Future<void> clear() async {
    await (handler as MyAudioHandler).clearPlaylist();
  }
  Future<void> addSingleInQueue(FileNode node,Work work)async {
    final mediaItem = _fileNodeToMediaItem(node,work);
    await add(mediaItem);
  }
  Future<void> handleFileTap(FileNode node,Work work,List<FileNode> currentNodes,{HistoryEntry? history}) async {
    if (node.isAudio) {
      final audioFiles = currentNodes.where((n) => n.isAudio).toList();
      final mediaList = audioFiles.map((node) {
        return _fileNodeToMediaItem(node,work);
      }).toList();
      final audioTapIndex = audioFiles.indexOf(node);
      await clear();
      await addAll(mediaList);
      await skipTo(audioTapIndex);
      if(history != null) {
        if (history.lastProgressMs != null) {
          await handler.seek(Duration(milliseconds: history.lastProgressMs!));
        }
      }
    }
  }
  Future<HistoryEntry?> checkHistoryForWork(Work work) async {
    final historyList = await CacheService.instance.getHistoryList();
    try {
      final history = historyList.firstWhere(
            (h) => h.work.id == work.id,
      );
      return history;
    }catch(e){
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
  /// 恢复播放指定历史记录
  Future<void> restoreHistory(List<FileNode> nodes, Work work, HistoryEntry history) async {
    if (history.lastTrackId == null) return;

    final found = findTrackParentAndIndex(nodes, history.lastTrackId!);
    if (found == null) return;

    final parentList = found['parentList'] as List<FileNode>;
    final index = found['index'] as int;
    final currentNode = parentList[index];
    handleFileTap(currentNode, work, parentList,history: history);
  }
  Future<void> removeMediaItemInQueue(int index) async {
    await handler.removeQueueItemAt(index);
    _saveState();
  }
  Future<void> addMultiInQueue(List<FileNode> nodes,Work work) async {
    final mediaList = nodes.map((node) {
      return _fileNodeToMediaItem(node,work);
    }).toList();
    await addAll(mediaList);
  }
  MediaItem _fileNodeToMediaItem(FileNode node, Work work) {
    return MediaItem(
      id: node.hash.toString(),
      album: node.workTitle,
      title: node.title,
      artist: OtherUtil.joinVAs(work.vas),
      artUri: Uri.parse(work.thumbnailCoverUrl ?? ''),
      extras: {
        'url': node.mediaStreamUrl,
        'mainCoverUrl': work.mainCoverUrl,
        'samCorverUrl': work.samCoverUrl,
        // 将其转化成多平台通用类型String,避免传输时导致类型模糊。
        'workData': jsonEncode(work),
      },
    );
  }
}
