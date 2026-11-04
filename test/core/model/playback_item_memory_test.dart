import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:vm_service/vm_service_io.dart';

void main() {
  test('prints PlaybackItem instance heap size at requested counts', () async {
    final serviceUri = (await developer.Service.getInfo()).serverWebSocketUri;
    if (serviceUri == null) {
      fail('Run this test with --enable-vmservice.');
    }
    final service = await vmServiceConnectUri(serviceUri.toString());
    addTearDown(service.dispose);
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere(
      (candidate) => candidate.isSystemIsolate != true,
    );

    Future<({int itemBytes, int originBytes, int stringBytes})>
    heapBytes() async {
      final profile = await service.getAllocationProfile(isolate.id!, gc: true);
      var itemBytes = 0;
      var originBytes = 0;
      var stringBytes = 0;
      for (final entry in profile.members!) {
        final name = entry.classRef?.name ?? '';
        final bytes = entry.bytesCurrent ?? 0;
        if (name.endsWith('PlaybackItem')) itemBytes += bytes;
        if (name.endsWith('FileOrigin')) originBytes += bytes;
        if (name.contains('String')) stringBytes += bytes;
      }
      return (
        itemBytes: itemBytes,
        originBytes: originBytes,
        stringBytes: stringBytes,
      );
    }

    final baseline = await heapBytes();
    final retained = <PlaybackItem>[];

    for (final target in [1000, 10000, 100000]) {
      for (var i = retained.length; i < target; i++) {
        final path = '/audio/album/track-$i.mp3';
        retained.add(
          PlaybackItem(
            id: 'track-id-$i',
            url: 'https://stream.example/audio/$i?token=$i',
            title: 'track-title-$i.mp3',
            isVideo: false,
            source: NodeSource.cloudDrive,
            scopeId: 'work-123',
            workId: 123,
            albumTitle: 'Album title',
            artist: 'Artist name',
            coverUrl: 'https://images.example/cover.jpg',
            smallCoverUrl: 'https://images.example/small-cover.jpg',
            durationMs: 180000 + i,
            siteId: 'webdav',
            remoteId: path,
            fileOrigin: FileOrigin(
              kind: FileOriginKind.webDav,
              connectionId: 'connection-1',
              filePath: path,
              rootPath: '/audio',
            ),
            path: path,
            rootPath: '/audio',
          ),
        );
      }

      final current = await heapBytes();
      final itemBytes = current.itemBytes - baseline.itemBytes;
      final originBytes = current.originBytes - baseline.originBytes;
      final stringBytes = current.stringBytes - baseline.stringBytes;
      final referencedBytes = originBytes + stringBytes;
      final totalBytes = itemBytes + referencedBytes;
      // ignore: avoid_print
      print(
        'PlaybackItem $target objects: $itemBytes bytes instance storage, '
        '$originBytes bytes FileOrigin, $stringBytes bytes String, '
        '$totalBytes bytes combined (excluding list storage)',
      );
      expect(itemBytes, target * 144);
      expect(originBytes, greaterThan(0));
      expect(stringBytes, greaterThan(0));
      expect(retained, hasLength(target));
    }
  });
}
