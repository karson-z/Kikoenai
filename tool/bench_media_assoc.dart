// Read-time vs write-time RJ/Work association benchmark.
//
// One size per process to avoid heap/GC carry-over; emits KEY=VALUE lines.
//
//   fvm dart compile exe tool/bench_media_assoc.dart -o build/bench/media_assoc
//   ./build/bench/media_assoc 100000
//
// Timings are the min of several iterations (robust against a busy desktop).
// ignore_for_file: avoid_print
import 'dart:math';

import 'package:kikoenai_core/core/utils/rj_code.dart';

int _sink = 0;

class BenchNode {
  BenchNode(this.path, this.folderPath, {this.workId});

  final String path;
  final String folderPath;
  int? workId;
}

class Dataset {
  Dataset(this.nodes, this.workCount, this.folderCount);

  final List<BenchNode> nodes;
  final int workCount;
  final int folderCount;
}

Dataset buildDataset(int fileCount, {int filesPerWork = 40, int seed = 7}) {
  final random = Random(seed);
  final nodes = <BenchNode>[];
  final folders = <String>{};
  var workIndex = 0;
  const rjBase = 1200000;

  while (nodes.length < fileCount) {
    final workId = rjBase + workIndex;
    final circle = 'circle_${workIndex % 140}';
    final rjName = workIndex % 3 == 0 ? 'RJ0$workId' : 'RJ$workId';
    final title = workIndex % 2 == 0 ? '' : ' 作品タイトル$workIndex';
    final workFolder = '/media/library/$circle/[$rjName]$title';
    final filesForWork = min(filesPerWork, fileCount - nodes.length);
    final useDisc = workIndex % 3 != 0;

    for (var i = 0; i < filesForWork; i++) {
      final String folder;
      if (useDisc) {
        folder = '$workFolder/disc${i % 2 + 1}';
      } else if (random.nextDouble() < 0.25) {
        folder = '$workFolder/特典';
      } else {
        folder = workFolder;
      }
      final file = '$folder/track_${i.toString().padLeft(3, '0')}.mp3';
      nodes.add(BenchNode(file, folder, workId: workId));
      folders.add(folder);
    }
    workIndex++;
  }
  return Dataset(nodes, workIndex, folders.length);
}

/// Nearest-ancestor RJ from a folder path, no cache.
int? resolveUncached(String folderPath) {
  var end = folderPath.length;
  while (end > 0) {
    final slash = folderPath.lastIndexOf('/', end - 1);
    final start = slash + 1;
    if (start < end) {
      final parsed = RjCode.parse(folderPath.substring(start, end));
      if (parsed != null) return parsed;
    }
    if (slash <= 0) break;
    end = slash;
  }
  return null;
}

/// Whole-folder-path memo: one parse per distinct folder, then a map hit.
int? resolveFolderCached(String folderPath, Map<String, int?> cache) {
  if (cache.containsKey(folderPath)) return cache[folderPath];
  final id = resolveUncached(folderPath);
  cache[folderPath] = id;
  return id;
}

Map<int, List<BenchNode>> buildLazyIndex(
  List<BenchNode> nodes,
  Map<String, int?> cache,
) {
  final index = <int, List<BenchNode>>{};
  for (final node in nodes) {
    final id = resolveFolderCached(node.folderPath, cache);
    if (id == null) continue;
    index.putIfAbsent(id, () => <BenchNode>[]).add(node);
  }
  return index;
}

int measureMinUs(void Function() action, {int warmup = 2, int iterations = 5}) {
  for (var i = 0; i < warmup; i++) {
    action();
  }
  var best = 1 << 62;
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    action();
    sw.stop();
    if (sw.elapsedMicroseconds < best) best = sw.elapsedMicroseconds;
  }
  return best;
}

void emit(String key, Object value) => print('$key=$value');

String ns(num totalUs, int count) =>
    (totalUs * 1000 / count).toStringAsFixed(1);

void main(List<String> args) {
  final fileCount = args.isEmpty ? 100000 : int.parse(args.first);
  final dataset = buildDataset(fileCount);
  final nodes = dataset.nodes;
  final random = Random(42);
  final workIds = <int>{for (final node in nodes) node.workId!}.toList();
  final targets = List<int>.generate(
    20,
    (_) => workIds[random.nextInt(workIds.length)],
  );

  emit('FILES', fileCount);
  emit('WORKS', dataset.workCount);
  emit('FOLDERS', dataset.folderCount);

  // ---- regex baseline -------------------------------------------------
  final folderNames = nodes
      .map((n) => n.folderPath)
      .toSet()
      .take(2000)
      .toList();
  final parse100k = measureMinUs(() {
    var hits = 0;
    for (var i = 0; i < 100000; i++) {
      if (RjCode.parse(folderNames[i % folderNames.length]) != null) hits++;
    }
    _sink += hits;
  });
  emit('REGEX_NS_CALL', ns(parse100k, 100000));

  // ---- write-time: parse every file path during scan -------------------
  var bestScan = 1 << 62;
  for (var run = 0; run < 5; run++) {
    for (final node in nodes) {
      node.workId = null;
    }
    final sw = Stopwatch()..start();
    for (final node in nodes) {
      node.workId = RjCode.parse(node.path);
    }
    sw.stop();
    if (sw.elapsedMicroseconds < bestScan) bestScan = sw.elapsedMicroseconds;
    _sink += nodes.length;
  }
  emit('WRITE_SCAN_MS', (bestScan / 1000).toStringAsFixed(2));
  emit('WRITE_SCAN_NS_FILE', ns(bestScan, nodes.length));

  // ---- write-time: current filter query (getWorkFileIndexLocally) ------
  final writeFilter = measureMinUs(() {
    var total = 0;
    for (final target in targets) {
      final matched = <BenchNode>[];
      for (final node in nodes) {
        if (node.workId == target) matched.add(node);
      }
      total += matched.length;
    }
    _sink += total;
  });
  emit(
    'WRITE_FILTER_US_QUERY',
    (writeFilter / targets.length).toStringAsFixed(1),
  );

  // ---- write-time: maintained index -----------------------------------
  final fieldIndex = <int, List<BenchNode>>{};
  for (final node in nodes) {
    fieldIndex.putIfAbsent(node.workId!, () => <BenchNode>[]).add(node);
  }
  final fieldLookup = measureMinUs(() {
    var total = 0;
    for (var i = 0; i < 10000; i++) {
      total += fieldIndex[targets[i % targets.length]]?.length ?? 0;
    }
    _sink += total;
  });
  emit('WRITE_INDEX_LOOKUP_NS', ns(fieldLookup, 10000));

  // ---- read-time: lazy index (first association use) ------------------
  late Map<int, List<BenchNode>> lazyIndex;
  final lazyBuild = measureMinUs(() {
    final cache = <String, int?>{};
    lazyIndex = buildLazyIndex(nodes, cache);
    _sink += lazyIndex.length;
  }, warmup: 3);
  emit('READ_LAZY_BUILD_MS', (lazyBuild / 1000).toStringAsFixed(2));
  final lazyLookup = measureMinUs(() {
    var total = 0;
    for (var i = 0; i < 10000; i++) {
      total += lazyIndex[targets[i % targets.length]]?.length ?? 0;
    }
    _sink += total;
  });
  emit('READ_LAZY_LOOKUP_NS', ns(lazyLookup, 10000));

  // ---- read-time: cold query, folder cache, no persistent index -------
  final coldQuery = measureMinUs(() {
    var total = 0;
    for (final target in targets) {
      final cache = <String, int?>{};
      var matched = 0;
      for (final node in nodes) {
        if (resolveFolderCached(node.folderPath, cache) == target) matched++;
      }
      total += matched;
    }
    _sink += total;
  });
  emit('READ_COLD_US_QUERY', (coldQuery / targets.length).toStringAsFixed(1));

  // ---- read-time: warm folder cache, still scanning nodes per query ---
  final globalFolderCache = <String, int?>{};
  for (final node in nodes) {
    resolveFolderCached(node.folderPath, globalFolderCache);
  }
  final warmQuery = measureMinUs(() {
    var total = 0;
    for (final target in targets) {
      var matched = 0;
      for (final node in nodes) {
        if (resolveFolderCached(node.folderPath, globalFolderCache) == target) {
          matched++;
        }
      }
      total += matched;
    }
    _sink += total;
  });
  emit('READ_WARM_US_QUERY', (warmQuery / targets.length).toStringAsFixed(1));

  // ---- read-time: no cache at all (worst case, 5 works) ---------------
  final noCacheTargets = targets.take(5).toList();
  final noCache = measureMinUs(
    () {
      var total = 0;
      for (final target in noCacheTargets) {
        var matched = 0;
        for (final node in nodes) {
          if (resolveUncached(node.folderPath) == target) matched++;
        }
        total += matched;
      }
      _sink += total;
    },
    warmup: 1,
    iterations: 3,
  );
  emit(
    'READ_NOCACHE_US_QUERY',
    (noCache / noCacheTargets.length).toStringAsFixed(1),
  );

  // ---- single playback association ------------------------------------
  final warmCache = <String, int?>{};
  for (final node in nodes) {
    resolveFolderCached(node.folderPath, warmCache);
  }
  final singleWarm = measureMinUs(() {
    var total = 0;
    for (var i = 0; i < 1000; i++) {
      total +=
          resolveFolderCached(
            nodes[random.nextInt(nodes.length)].folderPath,
            warmCache,
          ) ??
          0;
    }
    _sink += total;
  });
  emit('READ_SINGLE_WARM_NS', ns(singleWarm, 1000));
  final singleCold = measureMinUs(() {
    var total = 0;
    for (var i = 0; i < 1000; i++) {
      total +=
          resolveFolderCached(
            nodes[random.nextInt(nodes.length)].folderPath,
            <String, int?>{},
          ) ??
          0;
    }
    _sink += total;
  });
  emit('READ_SINGLE_COLD_NS', ns(singleCold, 1000));

  // ---- cloud batch: folder context vs per-file ------------------------
  final folders = nodes.map((n) => n.folderPath).toSet().take(100).toList();
  final cloudDirs = measureMinUs(() {
    final cache = <String, int?>{};
    var total = 0;
    for (final folder in folders) {
      total += resolveFolderCached(folder, cache) ?? 0;
    }
    _sink += total;
  });
  emit('CLOUD_100_DIRS_US', cloudDirs.toStringAsFixed(1));
  final cloudFiles = measureMinUs(() {
    final cache = <String, int?>{};
    var total = 0;
    for (var i = 0; i < 3000; i++) {
      total +=
          resolveFolderCached(
            nodes[random.nextInt(nodes.length)].folderPath,
            cache,
          ) ??
          0;
    }
    _sink += total;
  });
  emit('CLOUD_3000_FILES_US', cloudFiles.toStringAsFixed(1));

  // ---- cache sizes -----------------------------------------------------
  final cache = <String, int?>{};
  for (final node in nodes) {
    resolveFolderCached(node.folderPath, cache);
  }
  emit('CACHE_ENTRIES', cache.length);
  emit('SINK', _sink);
}
