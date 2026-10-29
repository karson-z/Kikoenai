import 'dart:developer' as developer;

import 'package:logger/logger.dart';

/// A callback boundary for local packages. The app owns the actual logger.
/// Events emitted before startup are replayed when the app binds its sink.
class PackageLog {
  const PackageLog({required this.tag});

  final String tag;
  static void Function(String tag, LogEvent event)? _sink;
  static final List<({String tag, LogEvent event})> _pending = [];

  static void bind(void Function(String tag, LogEvent event) sink) {
    _sink = sink;
    final pending = List.of(_pending);
    _pending.clear();
    for (final entry in pending) {
      sink(entry.tag, entry.event);
    }
  }

  void _write(Level level, dynamic message) {
    final event = LogEvent(level, message);
    final sink = _sink;
    if (sink != null) {
      sink(tag, event);
    } else {
      developer.log(
        '$message',
        name: tag,
        time: event.time,
        level: level == Level.error
            ? 1000
            : level == Level.warning
            ? 900
            : 500,
      );
      if (_pending.length >= 2000) _pending.removeAt(0);
      _pending.add((tag: tag, event: event));
    }
  }

  void d(dynamic message) => _write(Level.debug, message);
  void w(dynamic message) => _write(Level.warning, message);
  void e(dynamic message) => _write(Level.error, message);
}
