import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/service/lyrics/search_lyrics_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/utils/dlsite_image/rj_image_path.dart';
import 'package:kikoenai/core/widgets/player/provider/player_feedback_provider.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:path/path.dart' as p;

import '../../../../features/album/data/model/file_node.dart';
import '../../../service/cache/cache_service.dart';
import '../../../service/audio/audio_service.dart';
import '../state/player_state.dart';
import '../state/progress_state.dart';

final playerControllerProvider = NotifierProvider.autoDispose<PlayerController, AppPlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<AppPlayerState> {
  AudioHandler get _handler => AudioServiceSingleton.instance;
  CacheService get _cacheService => CacheService.instance;
  @override
  AppPlayerState build() {
    _listen();

    Future.microtask(() => _loadPlayerState());

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

    state = state.copyWith(
      subtitleList: savedState.subtitleList,
      currentSubtitle: savedState.currentSubtitle,
    );
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
        final workJson = workDataStr is String ? jsonDecode(workDataStr) : workDataStr;
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
  /// 监听播放状态变化
  void _listen() {
    // 播放状态 & 缓冲状态
    _handler.playbackState.listen((p) {
      final newProgress = ProgressBarState(
        current: p.position,
        buffered: p.bufferedPosition,
        total: _handler.mediaItem.value?.duration ?? Duration.zero,
      );
      state = state.copyWith(
        playing: p.playing,
        loading: p.processingState == AudioProcessingState.loading ||
            p.processingState == AudioProcessingState.buffering,
        progressBarState: newProgress,
      );
      _updateTrackerStatus(
          isPlaying: p.playing,
          isCompleted: p.processingState == AudioProcessingState.completed
      );
      if(state.currentTrack != null){
        _saveState();
        _saveHistory();
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
      if(state.currentTrack != null){
        _saveState();
        _saveHistory();
      }
      _updateTrackerStatus(mediaItem: item, isPlaying: state.playing);
    });

    // 播放列表变化
    _handler.queue.listen((queue) {
      state = state.copyWith(playlist: queue);
      _updateSkipInfo();
      if(state.currentTrack != null){
        _saveState();
      }
    });

    // 音量变化
    if (_handler is MyAudioHandler) {
      (_handler as MyAudioHandler).volumeStream.listen((v) {
        state = state.copyWith(volume: v);
        if(state.currentTrack != null){
          _saveState();
        }
      });
    }
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

      if(currentWork.id == null) return;

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
  // 添加字幕文件列表
  void addSubTitleFileList(List<FileNode> rootNode) {
    // 查找待添加的新文件
    final subFiles = SearchLyricsService.findSubTitlesInFiles(rootNode);

    final List<FileNode> resultList = List.from(state.subtitleList);

    final Set<String> seenTitles = state.subtitleList
        .map((e) => p.basenameWithoutExtension(e.title))
        .toSet();

    //  遍历新文件进行去重和添加
    for (var node in subFiles) {
      final String cleanTitle = p.basenameWithoutExtension(node.title);

      // 检查是否已存在
      if (!seenTitles.contains(cleanTitle)) {
        seenTitles.add(cleanTitle); // 标记为已存在
        resultList.add(node);       // 添加到结果列表
      }
    }

    if (resultList.length != state.subtitleList.length) {
      state = state.copyWith(subtitleList: resultList);
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
    await _handler.setShuffleMode(enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    _saveState();
  }

  Future<void> setRepeat(AudioServiceRepeatMode mode) async {
    state = state.copyWith(repeatMode: mode);
    await _handler.setRepeatMode(mode);
    _saveState();
  }
  // void replacePlaylist(List<MediaItem> newList) {
  //   _handler.updateQueue(newList);
  // }
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
    // 为什么只清除列表，不清除当前播放记录呢(清除的话播放器页面就会使用占位符进行替代，太丑了，不如不要)！
    state = state.copyWith(subtitleList: []); // 清空字幕列表
    await (_handler as MyAudioHandler).clearPlaylist();
  }
  // 私有方法，交给监听器触发
  void _updateSubtitleState(MediaItem? currentItem) async {
    // 1. 基础空值处理
    if (currentItem == null) {
      state = state.copyWith(subtitleList: [], currentSubtitle: null, currentTrack: null);
      return;
    }
    if (currentItem.id == state.currentTrack?.id) return;
    // 2. 获取 ID 进行比对
    final String? lastWorkId = _getWorkIdFromItem(state.currentTrack);
    final String? newWorkId = _getWorkIdFromItem(currentItem);
    final String currentSongName = currentItem.title;

    List<FileNode> targetSubtitleList = [];

    // 3. 判断是否需要重新加载字幕列表 (核心逻辑变更)
    // 只有当 WorkId 发生变化，或者当前列表为空但有 WorkId 时，才去执行耗时的树查找
    bool isWorkChanged = newWorkId != lastWorkId;

    if ((isWorkChanged) && newWorkId != null && newWorkId.isNotEmpty) {
      debugPrint("检测到作品变化或列表为空 (Old: $lastWorkId -> New: $newWorkId)，开始查找字幕...");
      // 当前作品发生变化，需要重新拉取字幕列表
      targetSubtitleList = SearchLyricsService.findSubtitleInLocalById(newWorkId);
      // 如果当前状态中没有字幕列表先匹配本地后匹配ASMR服务器上的字幕列表
      if(targetSubtitleList.isEmpty){
        targetSubtitleList = await SearchLyricsService.findSubtitleInNetWorkById(newWorkId, ref);
      }
    } else {
      // 作品未变化，直接复用当前 State 中的列表
      targetSubtitleList = List.from(state.subtitleList);
    }
    // 4. 在(新)列表中匹配当前播放的歌曲
    FileNode? bestMatchNode;
    if (targetSubtitleList.isNotEmpty) {
      final subtitleNames = targetSubtitleList.map((e) => e.title).toList();
      final bestMatchName = SearchLyricsService.findBestMatch(
        currentSongName,
        subtitleNames,
      );
      if (bestMatchName != null) {
        bestMatchNode = targetSubtitleList.firstWhere((e) => e.title == bestMatchName);
      }
    }

    // 5. 更新状态
    // 如果没有找到匹配的字幕文件，生成一个占位符，或者根据你的 UI 需求设为 null
    final newCurrentSubtitle = bestMatchNode ?? FileNode(type: NodeType.text, title: currentSongName, hash: '');

    state = state.copyWith(
      currentTrack: currentItem,
      subtitleList: targetSubtitleList,
      currentSubtitle: newCurrentSubtitle,
    );
  }
  Future<void> addSingleInQueue(FileNode node,Work work)async {
    final mediaItem = _fileNodeToMediaItem(node,work);
    await add(mediaItem);
  }
  Future<void> handleFileTap(
      FileNode node,
      List<FileNode> currentNodes,
      {
        HistoryEntry? history,
        Work? work
      }
      ) async {
    if (node.isAudio) {
      // 1. 准备数据
      final audioFiles = currentNodes.where((n) => n.isAudio).toList();
      final mediaList = audioFiles.map((n) {
        // 这里的 work ?? Work() 可能需要优化，确保有封面图
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
  Future<void> restoreHistory(List<FileNode> nodes, Work work, HistoryEntry history) async {
    if (history.lastTrackId == null) return;

    final found = findTrackParentAndIndex(nodes, history.lastTrackId!);
    if (found == null) return;

    final parentList = found['parentList'] as List<FileNode>;
    final index = found['index'] as int;
    final currentNode = parentList[index];
    await handleFileTap(
        currentNode,
        parentList,
        history: history,
        work: work
    );
  }
  Future<void> removeMediaItemInQueue(int index) async {
    await _handler.removeQueueItemAt(index);
    if(state.playlist.isEmpty){
      state = AppPlayerState();
    }
    _saveState();
  }
  Future<void> addMultiInQueue(List<FileNode> nodes,Work work) async {
    final mediaList = nodes.map((node) {
      return _fileNodeToMediaItem(node,work);
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
      // 其他情况（不做处理或重置为列表循环）
        await setRepeat(AudioServiceRepeatMode.all);
        break;
    }
  }
  MediaItem _fileNodeToMediaItem(FileNode node, Work work) {
    String? imagePath;

    // 当作品本身没有主封面时，尝试从路径推导
    if (work.mainCoverUrl == null) {
      final mediaUrl = node.mediaStreamUrl;
      if (mediaUrl != null) {
        final rjCode = RJPathUtils.getRjcode(mediaUrl);
        if (rjCode != null) {
          imagePath = RJPathUtils.buildPath(rjCode);
        }
      }
    }
    return MediaItem(
      id: node.hash.toString(),
      album: node.workTitle,
      title: node.title,
      artist: work.vas == null
          ? node.artist
          : OtherUtil.joinVAs(work.vas),

      // artUri 只放“明确可用的封面 URL”
      artUri: work.mainCoverUrl != null
          ? Uri.parse(work.mainCoverUrl!)
          : null,

      extras: {
        'url': node.mediaStreamUrl,
        'mainCoverUrl': work.mainCoverUrl ?? imagePath,
        'samCorverUrl': work.samCoverUrl ?? imagePath,
        'workData': jsonEncode(work),
      },
    );
  }
  String? _getWorkIdFromItem(MediaItem? item) {
    if (item == null) return null;
    final workData = item.extras?['workData'];
    if (workData == null) return null;
    try {
      // 兼容 JSON String 和 Map
      final workJson = workData is String ? jsonDecode(workData) : workData;
      return workJson['id']?.toString();
    } catch (e) {
      debugPrint("解析 WorkID 异常: $e");
      return null;
    }
  }
}
