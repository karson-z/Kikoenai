import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

typedef WebDavDirectoryLoader = Future<List<FileNode>> Function(String path);

enum WebDavMediaIndexPhase { idle, scanning, ready, error }

class WebDavMediaIndexState {
  const WebDavMediaIndexState({
    this.phase = WebDavMediaIndexPhase.idle,
    this.scannedDirectories = 0,
    this.indexedWorks = 0,
    this.lastUpdatedAt,
    this.message,
  });

  final WebDavMediaIndexPhase phase;
  final int scannedDirectories;
  final int indexedWorks;
  final DateTime? lastUpdatedAt;
  final String? message;
}

class WebDavMediaIndexSnapshot {
  const WebDavMediaIndexSnapshot({
    required this.fingerprint,
    required this.rootPath,
    required this.generatedAt,
    required this.pathsByWorkId,
  });

  final String fingerprint;
  final String rootPath;
  final DateTime generatedAt;
  final Map<int, List<String>> pathsByWorkId;

  List<String> pathsFor(int workId) => pathsByWorkId[workId] ?? const [];

  Map<String, dynamic> toJson() => {
    'fingerprint': fingerprint,
    'rootPath': rootPath,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'pathsByWorkId': {
      for (final entry in pathsByWorkId.entries)
        entry.key.toString(): entry.value,
    },
  };

  static WebDavMediaIndexSnapshot? fromJson(Object? value) {
    if (value is! Map) return null;
    final fingerprint = value['fingerprint'];
    final rootPath = value['rootPath'];
    final generatedAt = value['generatedAt'];
    final rawPaths = value['pathsByWorkId'];
    if (fingerprint is! String ||
        rootPath is! String ||
        generatedAt is! int ||
        rawPaths is! Map) {
      return null;
    }

    final parsedPaths = <int, List<String>>{};
    for (final entry in rawPaths.entries) {
      final workId = int.tryParse(entry.key.toString());
      if (workId == null || entry.value is! List) continue;
      parsedPaths[workId] = (entry.value as List).whereType<String>().toList(
        growable: false,
      );
    }
    return WebDavMediaIndexSnapshot(
      fingerprint: fingerprint,
      rootPath: rootPath,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(generatedAt),
      pathsByWorkId: parsedPaths,
    );
  }
}

class WebDavMediaIndexService {
  WebDavMediaIndexService._();

  static final WebDavMediaIndexService instance = WebDavMediaIndexService._();
  static const Duration maxAge = Duration(hours: 24);
  static const String _storagePrefix = 'dl_webdav_media_index.';
  static final RegExp _rjPattern = RegExp(
    r'(?:^|[^A-Za-z0-9])RJ0?(\d{7,9})(?!\d)',
    caseSensitive: false,
  );

  final ValueNotifier<WebDavMediaIndexState> state = ValueNotifier(
    const WebDavMediaIndexState(),
  );
  Future<WebDavMediaIndexSnapshot?>? _inFlight;
  String? _inFlightFingerprint;
  int _generation = 0;

  static String fingerprintFor({
    required String serverUrl,
    required String username,
    required String rootPath,
  }) {
    final value =
        '${serverUrl.trim()}\n${username.trim()}\n${_normalize(rootPath)}';
    return sha256.convert(utf8.encode(value)).toString();
  }

  WebDavMediaIndexSnapshot? read(String fingerprint) {
    try {
      return WebDavMediaIndexSnapshot.fromJson(
        AppStorage.settingsBox.get('$_storagePrefix$fingerprint'),
      );
    } catch (_) {
      return null;
    }
  }

  bool isFresh(WebDavMediaIndexSnapshot snapshot, {DateTime? now}) {
    return (now ?? DateTime.now()).difference(snapshot.generatedAt) < maxAge;
  }

  Future<WebDavMediaIndexSnapshot?> ensureFresh({
    required String fingerprint,
    required String rootPath,
    required WebDavDirectoryLoader loadDirectory,
    bool force = false,
  }) {
    final cached = read(fingerprint);
    if (!force && cached != null && isFresh(cached)) {
      state.value = WebDavMediaIndexState(
        phase: WebDavMediaIndexPhase.ready,
        indexedWorks: cached.pathsByWorkId.length,
        lastUpdatedAt: cached.generatedAt,
      );
      return Future.value(cached);
    }
    if (_inFlight != null && _inFlightFingerprint == fingerprint) {
      return _inFlight!;
    }

    final future = _rebuild(
      fingerprint: fingerprint,
      rootPath: rootPath,
      loadDirectory: loadDirectory,
    );
    _inFlight = future;
    _inFlightFingerprint = fingerprint;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightFingerprint = null;
      }
    });
  }

  void cancelActive() {
    _generation++;
    state.value = const WebDavMediaIndexState();
  }

  Future<WebDavMediaIndexSnapshot?> _rebuild({
    required String fingerprint,
    required String rootPath,
    required WebDavDirectoryLoader loadDirectory,
  }) async {
    final generation = ++_generation;
    final normalizedRoot = _normalize(rootPath);
    final queue = ListQueue<String>()..add(normalizedRoot);
    final visited = <String>{};
    final candidates = <int, Set<String>>{};
    var scannedDirectories = 0;
    state.value = const WebDavMediaIndexState(
      phase: WebDavMediaIndexPhase.scanning,
    );

    try {
      while (queue.isNotEmpty && generation == _generation) {
        final current = queue.removeFirst();
        final key = current.toLowerCase();
        if (!visited.add(key)) continue;
        final nodes = await loadDirectory(current);
        scannedDirectories++;

        for (final node in nodes) {
          final nodePath = _normalize(
            node.path ?? NodeFolder.joinPath(current, node.title),
          );
          final workIds = extractWorkIds(node.title);
          if (workIds.isNotEmpty) {
            final candidatePath = node.isFolder
                ? nodePath
                : _normalize(node.folderPath ?? current);
            for (final workId in workIds) {
              candidates
                  .putIfAbsent(workId, () => <String>{})
                  .add(candidatePath);
            }
            if (node.isFolder) continue;
          }
          if (node.isFolder) queue.add(nodePath);
        }

        state.value = WebDavMediaIndexState(
          phase: WebDavMediaIndexPhase.scanning,
          scannedDirectories: scannedDirectories,
          indexedWorks: candidates.length,
        );
      }
      if (generation != _generation) return read(fingerprint);

      final generatedAt = DateTime.now();
      final snapshot = WebDavMediaIndexSnapshot(
        fingerprint: fingerprint,
        rootPath: normalizedRoot,
        generatedAt: generatedAt,
        pathsByWorkId: {
          for (final entry in candidates.entries)
            entry.key: _removeNestedPaths(entry.value),
        },
      );
      await AppStorage.settingsBox.put(
        '$_storagePrefix$fingerprint',
        snapshot.toJson(),
      );
      state.value = WebDavMediaIndexState(
        phase: WebDavMediaIndexPhase.ready,
        scannedDirectories: scannedDirectories,
        indexedWorks: snapshot.pathsByWorkId.length,
        lastUpdatedAt: generatedAt,
      );
      return snapshot;
    } catch (error) {
      if (generation != _generation) return read(fingerprint);
      final previous = read(fingerprint);
      state.value = WebDavMediaIndexState(
        phase: WebDavMediaIndexPhase.error,
        scannedDirectories: scannedDirectories,
        indexedWorks: previous?.pathsByWorkId.length ?? 0,
        lastUpdatedAt: previous?.generatedAt,
        message: error.toString(),
      );
      return previous;
    }
  }

  static Set<int> extractWorkIds(String value) {
    return _rjPattern
        .allMatches(value)
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .toSet();
  }

  static List<String> _removeNestedPaths(Iterable<String> paths) {
    final sorted = paths.toSet().toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    final result = <String>[];
    for (final path in sorted) {
      final lower = path.toLowerCase();
      if (result.any((parent) {
        final parentLower = parent.toLowerCase();
        return lower == parentLower || lower.startsWith('$parentLower/');
      })) {
        continue;
      }
      result.add(path);
    }
    return result;
  }

  static String _normalize(String path) =>
      FileNodeLibraryIndex.normalizePath(path);
}
