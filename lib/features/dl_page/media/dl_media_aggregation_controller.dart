import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';

import 'dl_media_models.dart';
import 'dl_media_resolvers.dart';

abstract interface class DlMediaPreferenceRepository {
  String? read(int workId);

  Future<void> save(int workId, String sourceKey);
}

class HiveDlMediaPreferenceRepository implements DlMediaPreferenceRepository {
  static const String _prefix = 'dl_media_preference.';

  @override
  String? read(int workId) {
    try {
      final value = AppStorage.settingsBox.get('$_prefix$workId');
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(int workId, String sourceKey) =>
      AppStorage.settingsBox.put('$_prefix$workId', sourceKey);
}

final dlMediaPreferenceRepositoryProvider =
    Provider<DlMediaPreferenceRepository>(
      (ref) => HiveDlMediaPreferenceRepository(),
    );

final dlMediaAggregationProvider = NotifierProvider.autoDispose
    .family<DlMediaAggregationController, DlMediaAggregationState, int>(
      DlMediaAggregationController.new,
    );

class DlMediaAggregationController extends Notifier<DlMediaAggregationState> {
  DlMediaAggregationController(this.workId);

  static const Duration cacheDuration = Duration(minutes: 10);
  static final Map<int, _DlMediaCacheEntry> _cache = {};

  final int workId;
  final Map<DlMediaSourceKey, int> _sourceVersions = {};
  late List<DlMediaResolver> _resolvers;
  late DlMediaPreferenceRepository _preferenceRepository;
  String? _preferredStorageKey;
  bool _userSelected = false;
  int _allRequestVersion = 0;

  @override
  DlMediaAggregationState build() {
    _resolvers = ref.watch(dlMediaResolversProvider);
    _preferenceRepository = ref.watch(dlMediaPreferenceRepositoryProvider);
    _preferredStorageKey = _preferenceRepository.read(workId);
    ref.onDispose(() {
      _allRequestVersion++;
      for (final key in _sourceVersions.keys.toList()) {
        _sourceVersions[key] = (_sourceVersions[key] ?? 0) + 1;
      }
    });

    final cached = _cache[workId];
    final expectedKeys = _resolvers
        .map((resolver) => resolver.descriptor.key.storageKey)
        .toList(growable: false);
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < cacheDuration &&
        _sameKeys(cached.sourceKeys, expectedKeys)) {
      return _applyDefaultSelection(cached.state);
    }
    _cache.remove(workId);

    final initial = DlMediaAggregationState(
      sources: _resolvers
          .map(
            (resolver) => DlMediaSourceResult(
              descriptor: resolver.descriptor,
              status: DlMediaResolveStatus.loading,
            ),
          )
          .toList(growable: false),
      isRefreshingAll: true,
    );
    Future.microtask(_resolveAll);
    return initial;
  }

  Future<void> refreshAll() async {
    _cache.remove(workId);
    _userSelected = false;
    await _resolveAll(preserveExisting: true);
  }

  Future<void> refreshSource(DlMediaSourceKey key) async {
    final resolver = _resolverFor(key);
    if (resolver == null) return;
    _cache.remove(workId);
    await _resolveOne(resolver, preserveExisting: true);
    _cacheIfComplete();
  }

  Future<void> selectSource(DlMediaSourceKey key) async {
    final exists = state.visibleSources.any(
      (source) => source.descriptor.key == key,
    );
    if (!exists) return;
    _userSelected = true;
    _preferredStorageKey = key.storageKey;
    state = state.copyWith(selectedKey: key);
    _cacheIfComplete();
    try {
      await _preferenceRepository.save(workId, key.storageKey);
    } catch (_) {
      // The active selection remains valid even when its preference cannot persist.
    }
  }

  Future<void> _resolveAll({bool preserveExisting = false}) async {
    final requestVersion = ++_allRequestVersion;
    final previousByKey = {
      for (final source in state.sources) source.descriptor.key: source,
    };
    state = state.copyWith(
      sources: _resolvers
          .map((resolver) {
            final previous = previousByKey[resolver.descriptor.key];
            return DlMediaSourceResult(
              descriptor: resolver.descriptor,
              status: DlMediaResolveStatus.loading,
              index: preserveExisting ? previous?.index : null,
            );
          })
          .toList(growable: false),
      isRefreshingAll: true,
      clearSelectedKey: !preserveExisting,
    );

    final local = _resolvers
        .where(
          (resolver) => resolver.descriptor.key.kind == DlMediaSourceKind.local,
        )
        .firstOrNull;
    final pending = <Future<void>>[];
    if (local != null) {
      // Start local lookup first, then let every source resolve concurrently.
      pending.add(_resolveOne(local, preserveExisting: preserveExisting));
    }
    if (!ref.mounted || requestVersion != _allRequestVersion) return;
    final remaining = _resolvers.where((resolver) => resolver != local);
    pending.addAll(
      remaining.map(
        (resolver) => _resolveOne(resolver, preserveExisting: preserveExisting),
      ),
    );
    await Future.wait(pending);
    if (!ref.mounted || requestVersion != _allRequestVersion) return;
    state = state.copyWith(isRefreshingAll: false);
    _cacheIfComplete();
  }

  Future<void> _resolveOne(
    DlMediaResolver resolver, {
    required bool preserveExisting,
  }) async {
    final key = resolver.descriptor.key;
    final requestVersion = (_sourceVersions[key] ?? 0) + 1;
    _sourceVersions[key] = requestVersion;
    final previous = _resultFor(key);
    _replaceResult(
      DlMediaSourceResult(
        descriptor: resolver.descriptor,
        status: DlMediaResolveStatus.loading,
        index: preserveExisting ? previous?.index : null,
      ),
    );

    try {
      final index = await resolver.resolve(workId);
      if (!_isCurrent(key, requestVersion)) return;
      _replaceResult(
        DlMediaSourceResult(
          descriptor: resolver.descriptor,
          status: index == null
              ? DlMediaResolveStatus.empty
              : DlMediaResolveStatus.available,
          index: index,
        ),
      );
    } on DlMediaSourceUnavailable catch (error) {
      if (!_isCurrent(key, requestVersion)) return;
      _replaceResult(
        DlMediaSourceResult(
          descriptor: resolver.descriptor,
          status: DlMediaResolveStatus.unavailable,
          message: error.message,
        ),
      );
    } catch (error) {
      if (!_isCurrent(key, requestVersion)) return;
      _replaceResult(
        DlMediaSourceResult(
          descriptor: resolver.descriptor,
          status: DlMediaResolveStatus.error,
          index: preserveExisting ? previous?.index : null,
          message: error.toString(),
        ),
      );
    }
  }

  bool _isCurrent(DlMediaSourceKey key, int requestVersion) {
    return ref.mounted && _sourceVersions[key] == requestVersion;
  }

  DlMediaResolver? _resolverFor(DlMediaSourceKey key) {
    for (final resolver in _resolvers) {
      if (resolver.descriptor.key == key) return resolver;
    }
    return null;
  }

  DlMediaSourceResult? _resultFor(DlMediaSourceKey key) {
    for (final result in state.sources) {
      if (result.descriptor.key == key) return result;
    }
    return null;
  }

  void _replaceResult(DlMediaSourceResult result) {
    if (!ref.mounted) return;
    final sources = [
      for (final source in state.sources)
        if (source.descriptor.key == result.descriptor.key) result else source,
    ];
    state = state.copyWith(sources: sources);
    _reconcileSelection();
  }

  void _reconcileSelection() {
    final visible = state.visibleSources;
    if (visible.isEmpty) {
      state = state.copyWith(clearSelectedKey: true);
      return;
    }

    final local = visible
        .where(
          (source) => source.descriptor.key.kind == DlMediaSourceKind.local,
        )
        .firstOrNull;
    if (local != null && !_userSelected) {
      state = state.copyWith(selectedKey: local.descriptor.key);
      return;
    }

    if (!_userSelected && _preferredStorageKey != null) {
      final preferred = visible
          .where(
            (source) =>
                source.descriptor.key.storageKey == _preferredStorageKey,
          )
          .firstOrNull;
      if (preferred != null) {
        state = state.copyWith(selectedKey: preferred.descriptor.key);
        return;
      }
    }

    final currentStillExists = visible.any(
      (source) => source.descriptor.key == state.selectedKey,
    );
    if (!currentStillExists) {
      state = state.copyWith(selectedKey: visible.first.descriptor.key);
    }
  }

  void _cacheIfComplete() {
    if (state.hasLoading || state.isRefreshingAll) return;
    final sourceKeys = _resolvers
        .map((resolver) => resolver.descriptor.key.storageKey)
        .toList(growable: false);
    _cache[workId] = _DlMediaCacheEntry(
      createdAt: DateTime.now(),
      sourceKeys: sourceKeys,
      state: state,
    );
  }

  DlMediaAggregationState _applyDefaultSelection(
    DlMediaAggregationState cachedState,
  ) {
    final local = cachedState.visibleSources
        .where(
          (source) => source.descriptor.key.kind == DlMediaSourceKind.local,
        )
        .firstOrNull;
    if (local != null) {
      return cachedState.copyWith(selectedKey: local.descriptor.key);
    }
    if (_preferredStorageKey != null) {
      final preferred = cachedState.visibleSources
          .where(
            (source) =>
                source.descriptor.key.storageKey == _preferredStorageKey,
          )
          .firstOrNull;
      if (preferred != null) {
        return cachedState.copyWith(selectedKey: preferred.descriptor.key);
      }
    }
    return cachedState;
  }

  static bool _sameKeys(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _DlMediaCacheEntry {
  const _DlMediaCacheEntry({
    required this.createdAt,
    required this.sourceKeys,
    required this.state,
  });

  final DateTime createdAt;
  final List<String> sourceKeys;
  final DlMediaAggregationState state;
}
