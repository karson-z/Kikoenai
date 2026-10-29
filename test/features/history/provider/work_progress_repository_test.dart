import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/storage/work_progress_store.dart';
import 'package:kikoenai/features/history/provider/work_progress_repository.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

WorkProgressPoint _point(String scope, {int updatedAt = 100}) =>
    WorkProgressPoint(
      scopeKey: scope,
      itemId: '$scope/track.mp3',
      progressMs: 12345,
      updatedAt: updatedAt,
      sessionId: 'session-1',
    );

void main() {
  late Directory directory;
  final repository = WorkProgressRepository.instance;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('work_progress_keys_');
    Hive.init(directory.path);
    Hive.registerAdapter(WorkProgressPointAdapter());
  });

  setUp(() async {
    AppStorage.workProgressBox = await Hive.openBox<WorkProgressPoint>(
      'work_progress',
    );
    await AppStorage.workProgressBox.clear();
  });

  tearDown(() async => Hive.close());

  tearDownAll(() async => directory.delete(recursive: true));

  for (final scope in [
    'local_${'folder/' * 100}track.mp3',
    'cloud_${'网盘目录/🎵/' * 100}',
    'cloud_${Uri.encodeComponent('网盘目录/音频文件' * 100)}',
    // 即使字符数不到 255，UTF-8 编码后的长度也可能超过限制。
    'local_${'音' * 100}',
  ]) {
    test('长作用域以固定长度键落盘并能续播 (${scope.length} chars)', () async {
      final point = _point(scope);
      await repository.save(point);
      expect(repository.getByScope(scope), point);
      final key = AppStorage.workProgressBox.keys.single as String;
      expect(utf8.encode(key), hasLength(68));
      expect(key, isNot(scope));

      await Hive.close();
      AppStorage.workProgressBox = await Hive.openBox<WorkProgressPoint>(
        'work_progress',
      );
      expect(repository.getByScope(scope), point);
      await repository.delete(scope);
      expect(repository.getByScope(scope), isNull);
      expect(AppStorage.workProgressBox.isEmpty, isTrue);
    });
  }

  test('长路径只有末尾不同时不会覆盖彼此，重复保存原地更新', () async {
    final prefix = 'cloud_${'common-folder/' * 100}';
    final first = _point('${prefix}a');
    final second = _point('${prefix}b');
    await repository.save(first);
    await repository.save(second);
    final updated = first.copyWith(progressMs: 54321, updatedAt: 200);
    await repository.save(updated);

    expect(AppStorage.workProgressBox.length, 2);
    expect(repository.getByScope(first.scopeKey), updated);
    expect(repository.getByScope(second.scopeKey), second);
    await repository.delete(first.scopeKey);
    expect(repository.getByScope(second.scopeKey), second);
  });

  test('兼容读取旧键，成功保存后迁到新键且保留完整进度', () async {
    final old = _point('work_42');
    await AppStorage.workProgressBox.put(old.scopeKey, old);
    expect(repository.getByScope(old.scopeKey), old);
    final updated = old.copyWith(progressMs: 23456, updatedAt: 200);
    await repository.save(updated);

    expect(repository.getByScope(old.scopeKey), updated);
    expect(AppStorage.workProgressBox.containsKey(old.scopeKey), isFalse);
    expect(AppStorage.workProgressBox.length, 1);
  });

  test('删除旧键记录不会在下次读取时复活', () async {
    final old = _point('local_legacy-track');
    await AppStorage.workProgressBox.put(old.scopeKey, old);
    await repository.delete(old.scopeKey);
    expect(repository.getByScope(old.scopeKey), isNull);
    expect(AppStorage.workProgressBox.isEmpty, isTrue);
  });

  test('新旧键同时存在时读取最新进度，删除时一起清理', () async {
    final old = _point('cloud_legacy');
    final latest = old.copyWith(updatedAt: 300, progressMs: 56789);
    await repository.save(old);
    await AppStorage.workProgressBox.put(old.scopeKey, latest);
    expect(repository.getByScope(old.scopeKey), latest);
    await repository.delete(old.scopeKey);
    expect(AppStorage.workProgressBox.isEmpty, isTrue);
  });

  test('历史会话迁移产生的长作用域也通过相同存储入口落盘', () async {
    final item = PlaybackItem(
      id: 'track-1',
      url: 'https://example.test/track.mp3',
      title: 'track',
      source: NodeSource.cloudDrive,
      scopeId: '目录/' * 200,
    );
    final entry = HistoryEntry(
      session: PlaybackSession.fromQueue([item], id: 'session-1'),
      lastItemId: item.id,
      lastProgressMs: 67890,
      lastPlayTime: 500,
    );
    final migrated = HistoryMigration.buildSessionMaps([entry]);
    final store = WorkProgressStore(AppStorage.workProgressBox);
    for (final point in migrated.progress.values) {
      await store.save(point);
    }

    final point = repository.getByScope(item.scopeKey)!;
    expect(point.progressMs, 67890);
    expect(point.scopeKey, item.scopeKey);
    expect(point.sessionId, 'session-1');
    expect(AppStorage.workProgressBox.keys.single, hasLength(68));
  });

  test('清空历史仍会清空新旧断点记录', () async {
    final old = _point('work_legacy');
    await AppStorage.workProgressBox.put(old.scopeKey, old);
    await repository.save(_point('cloud_${'folder/' * 100}'));
    await repository.clear();
    expect(AppStorage.workProgressBox.isEmpty, isTrue);
  });
}
