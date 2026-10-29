import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:logger/logger.dart';
import 'package:kikoenai_core/core/utils/log/package_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Level previousLevel;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kikoenai_logger_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    previousLevel = Logger.level;
    Logger.level = Level.trace;
  });

  tearDown(() async {
    await KikoenaiLogOutput.flush();
    Logger.level = previousLevel;
    await directory.delete(recursive: true);
  });

  test(
    'multiline structured messages, error and supplied stack stay together',
    () {
      final printer = KikoenaiLogPrinter();
      final lines = printer.log(
        LogEvent(
          Level.error,
          {'任务': '下载', '状态': '失败'},
          time: DateTime(2026, 10, 29, 12, 30),
          error: StateError('offline'),
          stackTrace: StackTrace.fromString('#0 download (download.dart:42)'),
        ),
      );
      expect(
        lines.first,
        startsWith('[2026-10-29T12:30:00.000] [ERROR  ] [App]'),
      );
      expect(lines.skip(1).every((line) => line.startsWith('  │ ')), isTrue);
      final records = KikoenaiLogRecord.parse(lines.join('\n'));
      expect(records, hasLength(1));
      expect(records.single.level, Level.error);
      expect(records.single.message, contains('offline'));
      expect(records.single.message, contains('download.dart:42'));
    },
  );

  test(
    'ordinary debug records persist in order with their source tags',
    () async {
      final logger = KikoenaiLogger(tag: 'Scanner');
      for (var i = 0; i < 20; i++) {
        logger.d('文件 $i\n扫描完成');
      }
      final snapshot = await readLogSnapshot();
      expect(snapshot.records, hasLength(20));
      expect(snapshot.records.first.tag, 'Scanner');
      expect(snapshot.records.first.message, '文件 0\n扫描完成');
      expect(snapshot.records.last.message, '文件 19\n扫描完成');
      expect(snapshot.truncated, isFalse);
      expect(await readAllLogs(), contains('文件 19'));
    },
  );

  test('forceLog still bypasses the configured threshold', () async {
    Logger.level = Level.off;
    final logger = KikoenaiLogger(tag: 'MediaCenter');
    logger.d('filtered');
    logger.i('forced diagnostic', forceLog: true);
    final snapshot = await readLogSnapshot();
    expect(snapshot.records, hasLength(1));
    expect(snapshot.records.single.message, 'forced diagnostic');
    expect(snapshot.records.single.tag, 'MediaCenter');
  });

  test('old PrettyPrinter files remain readable next to new records', () {
    final records = KikoenaiLogRecord.parse('''[2026-10-28 17:53:15.000]
┌────────────────
│ old error
└────────────────

[2026-10-29T12:30:00.000] [DEBUG  ] [Scanner] new record
  │ second line

''');
    expect(records, hasLength(2));
    expect(records.first.tag, '历史日志');
    expect(records.first.message, contains('old error'));
    expect(records.last.message, 'new record\nsecond line');
  });

  test('bounded snapshots preserve the complete original file', () async {
    final file = await getLogsPath();
    final text = List.generate(
      30,
      (i) => '[2026-10-29T12:30:00.000] [DEBUG  ] [Test] 测试记录 $i\n\n',
    ).join();
    await file.writeAsString(text);
    final snapshot = await readLogSnapshot(maxBytes: 500, maxRecords: 3);
    expect(snapshot.records, hasLength(3));
    expect(snapshot.records.last.message, '测试记录 29');
    expect(snapshot.truncated, isTrue);
    expect(await readAllLogs(), text);
  });

  test(
    'clear removes saved and pending records and allows new writes',
    () async {
      final logger = KikoenaiLogger(tag: 'Test');
      logger.d('before clear');
      expect(await clearLogs(), isTrue);
      expect(await readAllLogs(), isEmpty);
      logger.d('after clear');
      expect((await readLogSnapshot()).records.single.message, 'after clear');
    },
  );

  test(
    'isolated tasks preserve logs, results and failures without platform calls',
    () async {
      final captured = await Isolate.run(
        () => KikoenaiLogOutput.capture(() {
          KikoenaiLogger(tag: 'Worker').d('后台扫描完成');
          return 42;
        }),
      );
      for (final text in captured.logs) {
        KikoenaiLogOutput.acceptForwarded(text);
      }
      expect(captured.value, 42);
      expect((await readLogSnapshot()).records.single.tag, 'Worker');
      final failed = await Isolate.run(
        () => KikoenaiLogOutput.capture<int>(() {
          KikoenaiLogger(tag: 'Worker').w('异常前的记录');
          throw StateError('worker failed');
        }),
      );
      for (final text in failed.logs) {
        KikoenaiLogOutput.acceptForwarded(text);
      }
      expect(() => failed.value, throwsStateError);
      expect((await readLogSnapshot()).records.last.message, '异常前的记录');
    },
  );

  test(
    'local packages use the app logger including inside background tasks',
    () async {
      KikoenaiLogger.initialize();
      const PackageLog(tag: 'Sites').e('站点连接失败');
      final captured = await Isolate.run(
        () => KikoenaiLogOutput.capture(() {
          const PackageLog(tag: 'WorkerPackage').d('后台包日志');
          return 7;
        }),
      );
      for (final text in captured.logs) {
        KikoenaiLogOutput.acceptForwarded(text);
      }
      expect(captured.value, 7);
      final records = (await readLogSnapshot()).records;
      expect(records.map((record) => record.tag), ['Sites', 'WorkerPackage']);
      expect(records.first.level, Level.error);
      expect(records.last.message, '后台包日志');
    },
  );

  test('credentials are redacted while useful diagnostic context remains', () {
    final text = redactLogText(
      '''GET https://user:pass@example.com/file?token=secret&name=track
Authorization: Bearer abc.def
Cookie: session=private
{"password": "secret", "token": "secret", "status": "ok"}''',
    );
    expect(text, isNot(contains('secret')));
    expect(text, isNot(contains('abc.def')));
    expect(text, isNot(contains('session=private')));
    expect(text, isNot(contains('user:pass')));
    expect(text, contains('name=track'));
    expect(text, contains('"status": "ok"'));
  });
}
