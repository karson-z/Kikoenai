import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/dl_page/media/webdav_media_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _folder(String title, String path) => FileNode(
  type: NodeType.folder,
  title: title,
  path: path,
  source: NodeSource.cloudDrive,
);

void main() {
  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'kikoenai_webdav_media_index_',
    );
    Hive.init(tempDirectory.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('RJ matching is exact and rejects prefixed or overlong ids', () {
    expect(WebDavMediaIndexService.extractWorkIds('RJ01234567 音声'), {1234567});
    expect(WebDavMediaIndexService.extractWorkIds('folder/RJ12345678-copy'), {
      12345678,
    });
    expect(WebDavMediaIndexService.extractWorkIds('XRJ01234567'), isEmpty);
    expect(WebDavMediaIndexService.extractWorkIds('RJ01234567890'), isEmpty);
  });

  test('index freshness expires after 24 hours', () {
    final service = WebDavMediaIndexService.instance;
    final now = DateTime(2026, 8, 31, 12);
    WebDavMediaIndexSnapshot snapshotAt(DateTime generatedAt) =>
        WebDavMediaIndexSnapshot(
          fingerprint: 'freshness',
          rootPath: '/',
          generatedAt: generatedAt,
          pathsByWorkId: const {},
        );

    expect(
      service.isFresh(
        snapshotAt(now.subtract(const Duration(hours: 23))),
        now: now,
      ),
      isTrue,
    );
    expect(
      service.isFresh(
        snapshotAt(now.subtract(const Duration(hours: 24))),
        now: now,
      ),
      isFalse,
    );
  });

  test('successful rebuild atomically indexes candidate folders', () async {
    final service = WebDavMediaIndexService.instance;
    service.cancelActive();
    const fingerprint = 'index-success';
    final directories = <String, List<FileNode>>{
      '/': [
        _folder('Library', '/Library'),
        _folder('RJ01234567 first', '/RJ01234567 first'),
        _folder('XRJ07654321 ignored', '/XRJ07654321 ignored'),
      ],
      '/Library': [_folder('RJ07654321 second', '/Library/RJ07654321 second')],
    };

    final snapshot = await service.ensureFresh(
      fingerprint: fingerprint,
      rootPath: '/',
      force: true,
      loadDirectory: (path) async => directories[path] ?? const [],
    );

    expect(snapshot?.pathsFor(1234567), ['/RJ01234567 first']);
    expect(snapshot?.pathsFor(7654321), ['/Library/RJ07654321 second']);
    expect(snapshot?.pathsByWorkId, hasLength(2));
    expect(service.state.value.phase, WebDavMediaIndexPhase.ready);
  });

  test('failed rebuild keeps the last complete index', () async {
    final service = WebDavMediaIndexService.instance;
    service.cancelActive();
    const fingerprint = 'index-retained';
    final initial = await service.ensureFresh(
      fingerprint: fingerprint,
      rootPath: '/',
      force: true,
      loadDirectory: (path) async => [
        _folder('RJ01234567 retained', '/RJ01234567 retained'),
      ],
    );

    final retained = await service.ensureFresh(
      fingerprint: fingerprint,
      rootPath: '/',
      force: true,
      loadDirectory: (path) async => throw StateError('offline'),
    );

    expect(
      retained?.generatedAt.millisecondsSinceEpoch,
      initial?.generatedAt.millisecondsSinceEpoch,
    );
    expect(retained?.pathsFor(1234567), ['/RJ01234567 retained']);
    expect(service.state.value.phase, WebDavMediaIndexPhase.error);
  });
}
