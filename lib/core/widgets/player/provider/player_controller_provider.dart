import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/enums/node_type.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/service/file_scanner_service.dart';
import 'package:kikoenai/core/service/search_lyrics_service.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/utils/dlsite_image/rj_image_path.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/local_media/data/service/tree_service.dart';
import 'package:path/path.dart' as p;

import '../../../../features/album/data/model/file_node.dart';
import '../../../../../core/service/cache_service.dart';
import '../../../service/audio_service.dart';
import '../state/player_state.dart';
import '../state/progress_state.dart';

final playerControllerProvider = NotifierProvider.autoDispose<PlayerController, AppPlayerState>(() {
  return PlayerController();
});

class PlayerController extends Notifier<AppPlayerState> {
  late final AudioHandler handler;
  CacheService get _cacheService => CacheService.instance;
  @override
  AppPlayerState build() {
    handler = ref.read(audioHandlerFutureProvider);
    _listen();
    _loadPlayerState();
    return AppPlayerState();
  }
  /// 从缓存恢复播放器状态
  void _loadPlayerState() async {
    // 1. 同步获取播放状态 (因为是内存读取，极快)
    final savedState = _cacheService.getPlayerState();
    if (savedState == null) return;

    // 2. 恢复播放列表
    final playList = savedState.playlist;
    if (playList.isNotEmpty) {
      await handler.addQueueItems(playList);
    }

    // 3. 恢复当前索引
    final currentIndex = playList.indexWhere(
          (item) => item.id == savedState.currentTrack?.id,
    );
    (handler as MyAudioHandler).setCurrentIndex(currentIndex >= 0 ? currentIndex : 0);

    // 4. 恢复播放进度
    final progress = savedState.progressBarState.current;
    if (progress > Duration.zero) {
      await handler.seek(progress);
    }

    // 5. 恢复字幕状态
    state = state.copyWith(
        subtitleList: savedState.subtitleList,
        currentSubtitle: savedState.currentSubtitle
    );

    // 6. 恢复音量
    if (handler is MyAudioHandler) {
      await (handler as MyAudioHandler).setVolume(savedState.volume);
    }

    // 7. 恢复循环/随机模式
    await handler.setRepeatMode(savedState.repeatMode);
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

  // 保存播放器状态 (同步调用)
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

      // 直接保存对象，无需 await
      _cacheService.addToHistory(history);

    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }
  // 添加字幕文件列表
  void addSubTitleFileList(List<FileNode> rootNode) {
    // 1. 查找待添加的新文件
    final subFiles = SearchLyricsService.findSubTitlesInFiles(rootNode);

    final List<FileNode> resultList = List.from(state.subtitleList);

    final Set<String> seenTitles = state.subtitleList
        .map((e) => p.basenameWithoutExtension(e.title))
        .toSet();

    // 2. 遍历新文件进行去重和添加
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
    // 为什么只清除列表，不清除当前播放记录呢(清除的话播放器页面就会使用占位符进行替代，太丑了，不如不要)！
    state = state.copyWith(subtitleList: []); // 清空字幕列表
    await (handler as MyAudioHandler).clearPlaylist();
  }
  // 私有方法，交给监听器触发
  void _updateSubtitleState(MediaItem? currentItem) async {
    // 1. 状态拦截
    if (currentItem?.id == state.currentTrack?.id) return;

    if (currentItem == null) {
      state = state.copyWith(subtitleList: [], currentSubtitle: null, currentTrack: null);
      return;
    }
    // 临时存放候选字幕列表
    List<FileNode> foundSubtitles = List.from(state.subtitleList);
    final currentSongName = currentItem.title;

    // 2. 如果当前 state 没有字幕，则去本地库查找
    if (foundSubtitles.isEmpty) {
      // 1. 获取缓存数据并构建树 (内存操作，很快)
      final subTitleFiles = await CacheService.instance.getCachedScanResults(mode: ScanMode.subtitles);
      final paths = await CacheService.instance.getScanRootPaths(mode: ScanMode.subtitles);

      // 这里的 fileTree 包含了文件夹结构和压缩包结构(因为之前的MediaTreeBuilder改造过)
      final fileTree = MediaTreeBuilder.build(subTitleFiles, paths);

      final workString = currentItem.extras?['workData'];

      if (workString != null) {
        try {
          final workJson = jsonDecode(workString);
          final workId = workJson['id']?.toString() ?? "";

          if (workId.isNotEmpty) {
            debugPrint("开始在内存树中查找 ID: $workId");

            // 2. 在树中查找目标节点
            final targetNode = SearchLyricsService.findNodeInTree(fileTree, workId);

            if (targetNode != null) {
              debugPrint("命中树节点: ${targetNode.title} (Hash: ${targetNode.hash})");

              // 3. 提取该节点下的所有字幕
              final subNodes = SearchLyricsService.flattenSubtitles(targetNode);

              if (subNodes.isNotEmpty) {
                foundSubtitles = subNodes;
                debugPrint("从缓存树中提取到 ${subNodes.length} 个字幕");
              }
            } else {
              debugPrint("缓存树中未找到匹配的文件夹或压缩包");
              //TODO 如果缓存没找到，是否要触发一次磁盘扫描？
            }
          }
        } catch (e) {
          debugPrint("处理树查找失败: $e");
        }
      }
    }

    // 3. 执行匹配算法
    FileNode? bestMatchNode;
    if (foundSubtitles.isNotEmpty) {
      final subtitleNames = foundSubtitles.map((e) => e.title).toList();
      final bestMatchName = SearchLyricsService.findBestMatch(
        currentSongName,
        subtitleNames,
      );

      if (bestMatchName != null) {
        bestMatchNode = foundSubtitles.firstWhere((e) => e.title == bestMatchName);
      }
    }

    // 4. 最终状态更新
    state = state.copyWith(
      currentTrack: currentItem,
      subtitleList: foundSubtitles,
      // 如果匹配到了就用匹配的，否则给一个占位符或保持为 null
      currentSubtitle: bestMatchNode ?? FileNode(type: NodeType.text, title: currentSongName),
    );
  }
  Future<void> addSingleInQueue(FileNode node,Work work)async {
    final mediaItem = _fileNodeToMediaItem(node,work);
    await add(mediaItem);
  }
  Future<void> handleFileTap(FileNode node,List<FileNode> currentNodes,{HistoryEntry? history,Work? work}) async {
    if (node.isAudio) {
      final audioFiles = currentNodes.where((n) => n.isAudio).toList();
      final mediaList = audioFiles.map((node) {
        return _fileNodeToMediaItem(node,work ?? Work()); //TODO 本地音频没有作品信息暂时不处理，且不做历史记录
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
    handleFileTap(currentNode, parentList,history: history,work: work);
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
      artUri: work.thumbnailCoverUrl != null
          ? Uri.parse(work.thumbnailCoverUrl!)
          : null,

      extras: {
        'url': node.mediaStreamUrl,

        'mainCoverUrl': work.mainCoverUrl ?? imagePath,

        'samCorverUrl': work.samCoverUrl ?? imagePath,
        'workData': jsonEncode(work),
      },
    );
  }
}
