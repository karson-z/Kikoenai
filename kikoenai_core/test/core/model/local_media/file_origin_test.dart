import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

const origin = FileOrigin(
  kind: FileOriginKind.webDav,
  connectionId: 'connection-a',
  filePath: '/音声/Folder/track.mp3',
  rootPath: '/音声',
);

FileNode node({FileOrigin? fileOrigin = origin}) => FileNode(
  type: NodeType.audio,
  title: 'track.mp3',
  path: origin.filePath,
  source: NodeSource.cloudDrive,
  siteId: 'webdav',
  remoteId: origin.filePath,
  mediaStreamUrl: 'https://cloud.example/dav/track.mp3?sign=keep',
  localMediaUrl: '/downloaded/track.mp3',
  fileOrigin: fileOrigin,
);

void main() {
  test(
    'origin preserves case and unicode and enforces directory boundaries',
    () {
      expect(origin.parentPath, '/音声/Folder');
      expect(origin.contains('/音声/Folder/a.mp3'), isTrue);
      expect(origin.contains('/音声2/a.mp3'), isFalse);
      expect(origin.contains('/音声/../private/a.mp3'), isFalse);
      expect(origin.contains('/音声/folder/a.mp3'), isTrue);
      expect(FileOrigin.normalizePath('//音声//Folder/'), '/音声/Folder');
      expect(FileOrigin.tryParse({'kind': 'unknown'}), isNull);
    },
  );

  test(
    'FileNode JSON, playback conversion and platform channel retain origin',
    () {
      final original = node();
      expect(FileNode.fromJson(original.toJson()).fileOrigin, origin);
      final restoredNode = FileNode.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );
      final playback = PlaybackItem.fromFileNode(restoredNode);
      expect(playback.url, '/downloaded/track.mp3');
      expect(restoredNode.mediaStreamUrl, contains('?sign=keep'));
      final media = playback.toMediaItem();
      final channelExtras = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(media.extras)),
      );
      final restored = PlaybackItem.fromMediaItem(
        media.copyWith(extras: channelExtras),
      );
      expect(restored.fileOrigin, origin);
      expect(restored.url, playback.url);
      expect(restored.id, playback.id);
      expect(restored.contentId, playback.contentId);
    },
  );

  test(
    'same paths and ETags on independent connections have distinct playback ids',
    () {
      final a = PlaybackItem.fromFileNode(node());
      final b = PlaybackItem.fromFileNode(
        node(
          fileOrigin: const FileOrigin(
            kind: FileOriginKind.webDav,
            connectionId: 'connection-b',
            filePath: '/音声/Folder/track.mp3',
            rootPath: '/音声',
          ),
        ),
      );
      expect(a.id, isNot(b.id));
      expect(
        PlaybackItem.fromFileNode(node(fileOrigin: null)).id,
        origin.filePath,
      );
    },
  );

  test(
    'new origin and old playback records survive real Hive close/reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'file_origin_hive_',
      );
      addTearDown(() async {
        await Hive.close();
        Hive.resetAdapters();
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      Hive.registerAdapter(NodeSourceAdapter());
      Hive.registerAdapter(FileOriginAdapter());
      Hive.registerAdapter(FileOriginKindAdapter());
      Hive.registerAdapter(PlaybackItemAdapter());
      Hive.registerAdapter(PlaybackSessionAdapter());
      var box = await Hive.openBox<PlaybackSession>('sessions');
      final original = PlaybackSession.fromQueue([
        PlaybackItem.fromFileNode(node()),
      ]);
      await box.put('new', original);
      await box.close();
      // Write the exact old 14-field payload, with no field 14 / FileOrigin.
      Hive.registerAdapter<PlaybackItem>(
        _LegacyPlaybackItemAdapter(),
        override: true,
      );
      box = await Hive.openBox<PlaybackSession>('sessions');
      const legacy = PlaybackItem(
        id: 'legacy',
        url: 'https://cloud.example/old.mp3',
        title: 'Old',
        source: NodeSource.cloudDrive,
        scopeId: '/album',
        siteId: 'webdav',
        remoteId: '/album/old.mp3',
      );
      await box.put('old', PlaybackSession.fromQueue([legacy]));
      await box.close();
      Hive.registerAdapter<PlaybackItem>(PlaybackItemAdapter(), override: true);
      box = await Hive.openBox<PlaybackSession>('sessions');
      expect(box.get('new')!.queue.single.fileOrigin, origin);
      expect(box.get('new')!.id, original.id);
      expect(box.get('old')!.queue.single, legacy);
      expect(box.get('old')!.queue.single.fileOrigin, isNull);
    },
  );
}

class _LegacyPlaybackItemAdapter extends TypeAdapter<PlaybackItem> {
  @override
  int get typeId => TypeIds.playbackItem;
  @override
  PlaybackItem read(BinaryReader reader) => PlaybackItemAdapter().read(reader);
  @override
  void write(BinaryWriter writer, PlaybackItem item) {
    final fields = [
      item.id,
      item.url,
      item.title,
      item.isVideo,
      item.source,
      item.scopeId,
      item.workId,
      item.albumTitle,
      item.artist,
      item.coverUrl,
      item.smallCoverUrl,
      item.durationMs,
      item.siteId,
      item.remoteId,
    ];
    writer.writeByte(fields.length);
    for (var i = 0; i < fields.length; i++) {
      writer
        ..writeByte(i)
        ..write(fields[i]);
    }
  }
}
