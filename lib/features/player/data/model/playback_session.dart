import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:uuid/uuid.dart';

part 'playback_session.freezed.dart';
part 'playback_session.g.dart';

@freezed
@HiveType(typeId: TypeIds.playbackItem, adapterName: 'PlaybackItemAdapter')
abstract class PlaybackItem with _$PlaybackItem {
  const PlaybackItem._();

  const factory PlaybackItem({
    @HiveField(0) required String id,
    @HiveField(1) required String url,
    @HiveField(2) required String title,
    @HiveField(3) @Default(false) bool isVideo,
    @HiveField(4) @Default(NodeSource.asmrServer) NodeSource source,

    /// Historical aggregation id.
    ///
    /// Tracks in the same network work or local work share a scopeId. Local
    /// singles usually use their own item id as the scopeId.
    @HiveField(5) required String scopeId,
    @HiveField(6) int? workId,
    @HiveField(7) String? albumTitle,
    @HiveField(8) String? artist,
    @HiveField(9) String? coverUrl,
    @HiveField(10) String? smallCoverUrl,
    @HiveField(11) int? durationMs,
  }) = _PlaybackItem;

  factory PlaybackItem.fromFileNode(
    FileNode node, {
    Work? work,
    String? scopeId,
    NodeSource? source,
  }) {
    final resolvedSource = source ?? node.source;
    final url = node.playablePath;
    final workId = node.workId ?? work?.id;
    final artist =
        _blankToNull(node.artist) ??
        _blankToNull(work == null ? null : OtherUtil.joinVAs(work.vas));
    final albumTitle =
        _blankToNull(node.workTitle) ??
        _blankToNull(work?.title) ??
        _blankToNull(work?.name);

    return PlaybackItem(
      id: node.keyId,
      url: url,
      title: node.title,
      isVideo:
          node.isVideo ||
          FileExtensions.video.any((ext) => url.toLowerCase().endsWith(ext)),
      source: resolvedSource,
      scopeId: scopeId ?? _deriveScopeId(node, workId, resolvedSource),
      workId: workId,
      albumTitle: albumTitle,
      artist: artist,
      coverUrl: work?.mainCoverUrl,
      smallCoverUrl: work?.samCoverUrl ?? work?.thumbnailCoverUrl,
      durationMs: node.duration == null
          ? null
          : (node.duration! * 1000).round(),
    );
  }

  factory PlaybackItem.fromMediaItem(
    MediaItem item, {
    Work? work,
    NodeSource? source,
  }) {
    final extras = item.extras ?? const <String, dynamic>{};
    final resolvedSource =
        source ??
        _nodeSourceFromName(extras['source'] as String?) ??
        _inferSourceFromUrl(extras['url'] as String?);
    final rawWorkId = extras['workId'];
    final workId =
        work?.id ??
        (rawWorkId is int
            ? rawWorkId
            : int.tryParse(rawWorkId?.toString() ?? ''));
    final url = extras['url'] as String? ?? item.id;
    final scopeId =
        extras['scopeId'] as String? ??
        switch (resolvedSource) {
          NodeSource.asmrServer => workId?.toString() ?? item.id,
          NodeSource.localWork => workId?.toString() ?? item.id,
          NodeSource.localSingle => item.id,
          NodeSource.cloudDrive => workId?.toString() ?? item.id,
        };

    return PlaybackItem(
      id: item.id,
      url: url,
      title: item.title,
      isVideo:
          extras['isVideo'] == true ||
          FileExtensions.video.any((ext) => url.toLowerCase().endsWith(ext)),
      source: resolvedSource,
      scopeId: scopeId,
      workId: workId,
      albumTitle: item.album ?? work?.title ?? work?.name,
      artist:
          item.artist ??
          _blankToNull(work == null ? null : OtherUtil.joinVAs(work.vas)),
      coverUrl:
          extras['mainCoverUrl'] as String? ??
          work?.mainCoverUrl ??
          item.artUri?.toString(),
      smallCoverUrl:
          (extras['samCoverUrl'] as String?) ??
          (extras['samCorverUrl'] as String?) ??
          work?.samCoverUrl ??
          work?.thumbnailCoverUrl,
      durationMs: item.duration?.inMilliseconds,
    );
  }

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);

  String? get displayCoverUrl => coverUrl ?? smallCoverUrl;

  bool get isLocal =>
      source == NodeSource.localWork || source == NodeSource.localSingle;

  MediaItem toMediaItem() {
    final artworkUrl = displayCoverUrl;
    return MediaItem(
      id: id,
      album: albumTitle,
      title: title,
      artist: artist,
      artUri: artworkUrl == null ? null : Uri.tryParse(artworkUrl),
      duration: duration,
      extras: {
        'url': url,
        'source': source.name,
        'scopeId': scopeId,
        'workId': workId,
        'mainCoverUrl': coverUrl,
        'samCoverUrl': smallCoverUrl,
        'isVideo': isVideo,
      },
    );
  }

  static String _deriveScopeId(FileNode node, int? workId, NodeSource source) {
    return switch (source) {
      NodeSource.asmrServer =>
        workId?.toString() ?? node.workTitle ?? node.keyId,
      NodeSource.localWork =>
        node.rootPath ?? node.folderPath ?? workId?.toString() ?? node.keyId,
      NodeSource.localSingle => node.keyId,
      NodeSource.cloudDrive =>
        node.rootPath ?? node.folderPath ?? workId?.toString() ?? node.keyId,
    };
  }
}

@freezed
@HiveType(
  typeId: TypeIds.playbackSession,
  adapterName: 'PlaybackSessionAdapter',
)
abstract class PlaybackSession with _$PlaybackSession {
  const PlaybackSession._();

  const factory PlaybackSession({
    @HiveField(0) required String id,
    @HiveField(1) @Default(0) int currentIndex,
    @HiveField(2) @Default([]) List<PlaybackItem> queue,
    @HiveField(3) required int createdAt,
    @HiveField(4) required int updatedAt,
  }) = _PlaybackSession;

  factory PlaybackSession.fromQueue(
    List<PlaybackItem> queue, {
    int initialIndex = 0,
    String? id,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return PlaybackSession(
      id: id ?? const Uuid().v4(),
      currentIndex: _safeIndex(initialIndex, queue.length),
      queue: queue,
      createdAt: now,
      updatedAt: now,
    );
  }

  PlaybackItem? get currentItem {
    if (currentIndex < 0 || currentIndex >= queue.length) return null;
    return queue[currentIndex];
  }

  MediaItem? get currentMediaItem => currentItem?.toMediaItem();

  List<MediaItem> get mediaItems =>
      queue.map((item) => item.toMediaItem()).toList(growable: false);

  PlaybackItem? itemById(String id) {
    for (final item in queue) {
      if (item.id == id) return item;
    }
    return null;
  }

  PlaybackSession withCurrentIndex(int index) {
    return copyWith(
      currentIndex: _safeIndex(index, queue.length),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  PlaybackSession withQueue(List<PlaybackItem> nextQueue, {int? nextIndex}) {
    return copyWith(
      queue: nextQueue,
      currentIndex: _safeIndex(nextIndex ?? currentIndex, nextQueue.length),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

extension PlaybackItemListMediaItemX on Iterable<PlaybackItem> {
  List<MediaItem> toMediaItems() {
    return map((track) => track.toMediaItem()).toList(growable: false);
  }
}

String? _blankToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

NodeSource _inferSourceFromUrl(String? url) {
  if (url == null) return NodeSource.asmrServer;
  if (url.startsWith('/') || url.startsWith('file://')) {
    return NodeSource.localWork;
  }
  return NodeSource.asmrServer;
}

NodeSource? _nodeSourceFromName(String? name) {
  if (name == null) return null;
  for (final source in NodeSource.values) {
    if (source.name == name) return source;
  }
  return null;
}

int _safeIndex(int index, int length) {
  if (length <= 0) return -1;
  if (index < 0) return 0;
  if (index >= length) return length - 1;
  return index;
}
