import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

PlaybackItem _item(
  String id, {
  NodeSource source = NodeSource.asmrServer,
  String scopeId = 'album-A',
  int? workId,
  String? siteId,
  String? remoteId,
  String albumTitle = 'Album A',
}) {
  return PlaybackItem(
    id: id,
    url: 'https://example.test/$id.mp3',
    title: 'Track $id',
    source: source,
    scopeId: scopeId,
    workId: workId,
    albumTitle: albumTitle,
    siteId: siteId,
    remoteId: remoteId,
  );
}

HistoryEntry _entry(
  String sessionId,
  List<PlaybackItem> queue, {
  String? lastItemId,
  int lastPlayTime = 1000,
  int? lastProgressMs,
}) {
  final session = PlaybackSession.fromQueue(queue, id: sessionId);
  return HistoryEntry(
    session: session,
    lastItemId: lastItemId ?? queue.first.id,
    lastPlayTime: lastPlayTime,
    lastProgressMs: lastProgressMs,
  );
}

void main() {
  group('PlaybackItem.scopeKey', () {
    test('网络作品带站点身份时按站点+远端 id 聚合', () {
      final item = _item(
        't1',
        workId: 42,
        siteId: 'site.example',
        remoteId: '42',
      );
      expect(item.scopeKey, 'work_site.example:42');
    });

    test('无站点身份时退回 scopeId', () {
      final item = _item('t1', workId: 42, scopeId: 'legacy-scope');
      expect(item.scopeKey, 'work_legacy-scope');
    });

    test('本地单曲以曲目 id 独立成键', () {
      final item = _item(
        'single-1',
        source: NodeSource.localSingle,
        scopeId: 'single-1',
      );
      expect(item.scopeKey, 'single_single-1');
    });

    test('云盘目录按 scopeId 聚合', () {
      final item = _item(
        'cloud-1',
        source: NodeSource.cloudDrive,
        scopeId: 'cloud-root',
      );
      expect(item.scopeKey, 'cloud_cloud-root');
    });
  });

  group('HistoryMigration.buildSessionMaps', () {
    test('混合队列共享同一 session.id 时只保留最新一条', () {
      // 旧数据形态：同一队列快照被写成两条作用域记录
      final queue = [
        _item('a1', scopeId: 'A', workId: 1, albumTitle: 'A'),
        _item('b1', scopeId: 'B', workId: 2, albumTitle: 'B'),
      ];
      final old1 = _entry('shared-session', queue, lastPlayTime: 1000);
      final old2 = _entry('shared-session', queue, lastPlayTime: 2000);

      final result = HistoryMigration.buildSessionMaps([old1, old2]);

      expect(result.sessions.length, 1);
      expect(result.sessions['shared-session']!.lastPlayTime, 2000);
    });

    test('按作用域推导进度索引且每个作用域只留最新', () {
      final early = _entry(
        's1',
        [_item('a1', scopeId: 'A', workId: 1)],
        lastPlayTime: 1000,
        lastProgressMs: 500,
      );
      final late = _entry(
        's2',
        [_item('a2', scopeId: 'A', workId: 1)],
        lastPlayTime: 3000,
        lastProgressMs: 900,
      );

      final result = HistoryMigration.buildSessionMaps([early, late]);

      expect(result.progress.length, 1);
      // siteId 为空的网络作品按 scopeId 聚合（与旧 primaryKey 行为一致）
      final point = result.progress['work_A']!;
      expect(point.itemId, 'a2');
      expect(point.progressMs, 900);
      expect(point.sessionId, 's2');
      // 两条是不同会话，均保留在会话表中
      expect(result.sessions.length, 2);
    });

    test('空队列与定位不到曲目的脏数据被丢弃', () {
      final emptyQueue = _entry('s1', [], lastItemId: 'ghost');
      final result = HistoryMigration.buildSessionMaps([emptyQueue]);
      expect(result.sessions, isEmpty);
      expect(result.progress, isEmpty);
    });

    test('迁移结果可直接作为新会话表写入（键即 session.id）', () {
      final entry = _entry('session-x', [
        _item('a1', scopeId: 'A', workId: 7),
      ], lastPlayTime: 1234);
      final result = HistoryMigration.buildSessionMaps([entry]);
      expect(result.sessions.keys, contains('session-x'));
    });
  });

  group('会话历史键语义', () {
    test('同一 session.id 的两次保存代表同一条历史（原地更新）', () {
      final queue = [_item('a1', scopeId: 'A', workId: 1)];
      final first = _entry('same-id', queue, lastPlayTime: 1000);
      final second = _entry('same-id', queue, lastPlayTime: 2000);

      // repository 以 session.id 为键 upsert，模拟两次写入后的最终值
      final box = <String, HistoryEntry>{};
      box[first.session.id] = first;
      box[second.session.id] = second;

      expect(box.length, 1);
      expect(box['same-id']!.lastPlayTime, 2000);
    });

    test('不同 session.id 产生独立的历史条目', () {
      final queue = [_item('a1', scopeId: 'A', workId: 1)];
      final s1 = _entry('id-1', queue, lastPlayTime: 1000);
      final s2 = _entry('id-2', queue, lastPlayTime: 2000);

      final box = <String, HistoryEntry>{};
      box[s1.session.id] = s1;
      box[s2.session.id] = s2;

      expect(box.length, 2);
    });
  });
}
