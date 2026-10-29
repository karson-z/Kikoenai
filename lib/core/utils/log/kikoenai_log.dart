import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import 'package:kikoenai_core/core/utils/log/package_log.dart';

const Symbol _forceLogKey = #_forceLog;
const Symbol _tagKey = #_logTag;
const Symbol _sinkKey = #_logSink;

class KikoenaiLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) =>
      Zone.current[_forceLogKey] == true ||
      event.level.index >= Logger.level.index;
}

/// The console and file use the same plain-text format. Continuation lines stay
/// attached to their event, including errors and explicitly supplied stacks.
class KikoenaiLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final tag = Zone.current[_tagKey] as String? ?? 'App';
    String message;
    try {
      final value = event.message is Function ? event.message() : event.message;
      message = value is Map || value is List
          ? const JsonEncoder.withIndent('  ').convert(value)
          : '$value';
    } catch (_) {
      message = '${event.message}';
    }
    final body = StringBuffer(message);
    if (event.error != null) body.write('\n异常: ${event.error}');
    final stack =
        event.stackTrace ??
        (event.error == null
            ? null
            : StackTrace.fromString(
                StackTrace.current
                    .toString()
                    .split('\n')
                    .where(
                      (line) =>
                          !line.contains('package:logger/') &&
                          !line.contains('kikoenai_log.dart'),
                    )
                    .take(8)
                    .join('\n'),
              ));
    if (stack != null) body.write('\n堆栈:\n$stack');
    final lines = redactLogText(
      body.toString(),
    ).replaceAll('\r\n', '\n').split('\n');
    return [
      '[${event.time.toIso8601String()}] '
          '[${event.level.name.toUpperCase().padRight(7)}] [$tag] ${lines.first}',
      ...lines.skip(1).map((line) => '  │ $line'),
    ];
  }
}

class KikoenaiLogOutput extends LogOutput {
  static final Lock _logLock = Lock();
  static final List<String> _pending = [];
  static bool _scheduled = false;
  static String? _lastWriteError;

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      // The only console sink. Calling the logger here would recurse.
      // ignore: avoid_print
      print(line);
    }
    final text = '${event.lines.join('\n')}\n\n';
    final sink = Zone.current[_sinkKey] as void Function(String)?;
    if (sink != null) {
      sink(text);
    } else {
      acceptForwarded(text);
    }
  }

  /// Background tasks forward formatted events to the main isolate so they do
  /// not invoke platform channels or race the main isolate's file writes.
  static T runWithSink<T>(void Function(String) sink, T Function() action) =>
      runZoned(() {
        KikoenaiLogger.initialize();
        return action();
      }, zoneValues: {_sinkKey: sink});

  static void acceptForwarded(String text) {
    _pending.add(text);
    _scheduleFlush();
  }

  static Future<KikoenaiLogCapture<T>> capture<T>(
    FutureOr<T> Function() action,
  ) async {
    final logs = <String>[];
    try {
      final value = await runWithSink(logs.add, action);
      return KikoenaiLogCapture<T>._(value, logs, null, null);
    } catch (error, stack) {
      return KikoenaiLogCapture<T>._(null, logs, error, stack);
    }
  }

  static void _scheduleFlush() {
    if (!_scheduled) {
      _scheduled = true;
      scheduleMicrotask(() async {
        var success = false;
        try {
          await flush();
          success = true;
        } catch (error) {
          // File output must never interrupt playback, storage or startup.
          final reason = '$error'.split('\n').first;
          if (_lastWriteError != reason) {
            _lastWriteError = reason;
            // ignore: avoid_print
            print('[KikoenaiLogger] 写入日志失败: $reason');
          }
          // Bound retry memory when storage is unavailable; existing files are
          // never rotated or removed automatically.
          if (_pending.length > 2000) {
            _pending.removeRange(0, _pending.length - 2000);
          }
        } finally {
          _scheduled = false;
          if (success && _pending.isNotEmpty) _scheduleFlush();
        }
      });
    }
  }

  static Future<void> flush() => _logLock.synchronized(() async {
    while (_pending.isNotEmpty) {
      final count = _pending.length;
      final batch = _pending.take(count).join();
      final file = await getLogsPath();
      await file.writeAsString(batch, mode: FileMode.writeOnlyAppend);
      _pending.removeRange(0, count);
      _lastWriteError = null;
    }
  });
}

class KikoenaiLogger {
  KikoenaiLogger._(this.tag);

  static final Map<String, KikoenaiLogger> _instances = {};
  factory KikoenaiLogger({String tag = 'App'}) {
    initialize();
    return _instances.putIfAbsent(tag, () => KikoenaiLogger._(tag));
  }

  static bool _initialized = false;

  /// Local packages provide events through a callback. All formatting and file
  /// access stay in this file; packages never depend back on the app.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    PackageLog.bind((tag, event) {
      runZoned(
        () => _logger.log(
          event.level,
          event.message,
          time: event.time,
          error: event.error,
          stackTrace: event.stackTrace,
        ),
        zoneValues: {_tagKey: tag},
      );
    });
  }

  final String tag;
  static final Logger _logger = Logger(
    filter: KikoenaiLogFilter(),
    printer: KikoenaiLogPrinter(),
    output: KikoenaiLogOutput(),
  );

  void _log(
    Level level,
    dynamic message,
    Object? error,
    StackTrace? stackTrace,
    bool forceLog,
  ) {
    runZoned(
      () => _logger.log(level, message, error: error, stackTrace: stackTrace),
      zoneValues: {_forceLogKey: forceLog, _tagKey: tag},
    );
  }

  void t(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.trace, message, error, stackTrace, forceLog);
  void d(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.debug, message, error, stackTrace, forceLog);
  void i(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.info, message, error, stackTrace, forceLog);
  void w(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.warning, message, error, stackTrace, forceLog);
  void e(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.error, message, error, stackTrace, forceLog);
  void f(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    bool forceLog = false,
  }) => _log(Level.fatal, message, error, stackTrace, forceLog);
}

Future<File> getLogsPath() async {
  final dir = await getApplicationSupportDirectory();
  final directory = Directory(p.join(dir.path, 'logs'));
  await directory.create(recursive: true);
  // Keep the existing path so previous logs remain accessible.
  final file = File(p.join(directory.path, 'kikoenai_logs.log'));
  if (!await file.exists()) await file.create();
  return file;
}

Future<bool> clearLogs() async {
  try {
    await KikoenaiLogOutput._logLock.synchronized(() async {
      final file = await getLogsPath();
      final count = KikoenaiLogOutput._pending.length;
      await file.writeAsString('');
      KikoenaiLogOutput._pending.removeRange(0, count);
    });
    return true;
  } catch (error) {
    KikoenaiLogger(tag: 'Logger').e('清空日志失败', error: error);
    return false;
  }
}

class KikoenaiLogRecord {
  const KikoenaiLogRecord({
    required this.text,
    required this.message,
    this.time,
    this.level,
    this.tag = '历史日志',
  });

  final String text;
  final String message;
  final DateTime? time;
  final Level? level;
  final String tag;

  static final _ansi = RegExp(r'\x1B\[[0-9;]*m');
  static final _header = RegExp(
    r'^\[([^\]]+)\] \[([A-Z]+)\s*\] \[([^\]]*)\] (.*)$',
  );
  static final _legacyHeader = RegExp(r'^\[(\d{4}-\d\d-\d\d[^\]]*)\]$');

  /// Supports both the new records and the previous PrettyPrinter file format.
  static List<KikoenaiLogRecord> parse(String content) {
    final result = <KikoenaiLogRecord>[];
    final lines = <String>[];
    void finish() {
      if (lines.isEmpty) return;
      final text = lines.join('\n').trimRight();
      lines.clear();
      if (text.trim().isEmpty) return;
      final parts = text.split('\n');
      final header = _header.firstMatch(parts.first);
      final legacy = _legacyHeader.firstMatch(parts.first);
      final levelName =
          header?.group(2) ??
          RegExp(
            r'\b(TRACE|DEBUG|INFO|WARNING|ERROR|FATAL)\b',
          ).firstMatch(text)?.group(1);
      final level = Level.values.where(
        (l) => l.name.toUpperCase() == levelName,
      );
      result.add(
        KikoenaiLogRecord(
          text: text,
          time: DateTime.tryParse(header?.group(1) ?? legacy?.group(1) ?? ''),
          level: level.isEmpty ? null : level.first,
          tag: header?.group(3) ?? '历史日志',
          message: header == null
              ? text
              : [
                  header.group(4)!,
                  ...parts
                      .skip(1)
                      .map(
                        (line) =>
                            line.startsWith('  │ ') ? line.substring(4) : line,
                      ),
                ].join('\n').trimRight(),
        ),
      );
    }

    for (final line in content.replaceAll(_ansi, '').split('\n')) {
      if (_header.hasMatch(line) || _legacyHeader.hasMatch(line)) finish();
      lines.add(line);
    }
    finish();
    return result;
  }
}

class KikoenaiLogSnapshot {
  const KikoenaiLogSnapshot(this.records, this.fileBytes, this.truncated);
  final List<KikoenaiLogRecord> records;
  final int fileBytes;
  final bool truncated;
}

/// Read a bounded tail for the viewer without deleting any log history.
Future<KikoenaiLogSnapshot> readLogSnapshot({
  int maxBytes = 2 * 1024 * 1024,
  int maxRecords = 2000,
}) async {
  await KikoenaiLogOutput.flush();
  return KikoenaiLogOutput._logLock.synchronized(() async {
    final file = await getLogsPath();
    if (!await file.exists()) return const KikoenaiLogSnapshot([], 0, false);
    final handle = await file.open();
    try {
      final length = await handle.length();
      final offset = length > maxBytes ? length - maxBytes : 0;
      await handle.setPosition(offset);
      var content = utf8.decode(
        await handle.read(length - offset),
        allowMalformed: true,
      );
      if (offset > 0) {
        // The first event may start before the byte boundary; omit that fragment.
        final nextHeader = RegExp(
          r'^\[\d{4}-\d\d-\d\d',
          multiLine: true,
        ).firstMatch(content);
        content = nextHeader == null ? '' : content.substring(nextHeader.start);
      }
      final records = KikoenaiLogRecord.parse(content);
      return KikoenaiLogSnapshot(
        records.length > maxRecords
            ? records.sublist(records.length - maxRecords)
            : records,
        length,
        offset > 0 || records.length > maxRecords,
      );
    } finally {
      await handle.close();
    }
  });
}

Future<String> readAllLogs() async {
  await KikoenaiLogOutput.flush();
  return KikoenaiLogOutput._logLock.synchronized(() async {
    final file = await getLogsPath();
    return await file.exists() ? file.readAsString() : '';
  });
}

/// Avoid persisting credentials from HTTP diagnostics. Only the logged text is
/// changed; requests, stored sessions and permission flows remain untouched.
String redactLogText(String text) {
  var result = text.replaceAllMapped(
    RegExp(r'\b(Bearer|Basic)\s+[A-Za-z0-9+/=_\.\-]+', caseSensitive: false),
    (match) => '${match[1]} <redacted>',
  );
  result = result.replaceAllMapped(
    RegExp(
      r'([?&](?:access_token|refresh_token|token|password|passwd|api_key|apikey|sign|signature)=)[^&\s]*',
      caseSensitive: false,
    ),
    (match) => '${match[1]}<redacted>',
  );
  result = result.replaceAllMapped(
    RegExp(
      r'''((?:["']?)(?:authorization|cookie|set-cookie|password|passwd|access_token|refresh_token|token|api_key|apikey)(?:["']?)\s*:\s*)(?:"[^"]*"|'[^']*'|[^\r\n,}]+)''',
      caseSensitive: false,
    ),
    (match) => '${match[1]}<redacted>',
  );
  return result.replaceAllMapped(
    RegExp(r'(https?://)[^\s/@:]+:[^\s/@]+@', caseSensitive: false),
    (match) => '${match[1]}<redacted>@',
  );
}

/// File access boundary used by the viewer and replaceable in widget tests.
class KikoenaiLogStore {
  const KikoenaiLogStore();
  Future<KikoenaiLogSnapshot> readSnapshot() => readLogSnapshot();
  Future<String> readAll() => readAllLogs();
  Future<bool> clear() => clearLogs();
}

/// Transferable result of an isolated task, including logs emitted before an
/// exception. The caller enqueues the logs before accessing [value].
class KikoenaiLogCapture<T> {
  const KikoenaiLogCapture._(this._value, this.logs, this._error, this._stack);
  final T? _value;
  final List<String> logs;
  final Object? _error;
  final StackTrace? _stack;

  T get value {
    if (_error != null) Error.throwWithStackTrace(_error, _stack!);
    return _value as T;
  }
}
