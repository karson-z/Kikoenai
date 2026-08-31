import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

enum DlMediaSourceKind { local, contentSite, alist, webDav }

class DlMediaSourceKey {
  const DlMediaSourceKey({
    required this.kind,
    required this.providerId,
    this.instanceId,
  });

  final DlMediaSourceKind kind;
  final String providerId;
  final String? instanceId;

  String get storageKey => [
    kind.name,
    Uri.encodeComponent(providerId),
    if (instanceId != null) Uri.encodeComponent(instanceId!),
  ].join(':');

  @override
  bool operator ==(Object other) =>
      other is DlMediaSourceKey && other.storageKey == storageKey;

  @override
  int get hashCode => storageKey.hashCode;
}

class DlMediaSourceDescriptor {
  const DlMediaSourceDescriptor({
    required this.key,
    required this.label,
    required this.nodeSource,
  });

  final DlMediaSourceKey key;
  final String label;
  final NodeSource nodeSource;
}

abstract interface class DlMediaResolver {
  DlMediaSourceDescriptor get descriptor;

  Future<FileNodeLibraryIndex?> resolve(int workId);
}

class DlMediaSourceUnavailable implements Exception {
  const DlMediaSourceUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

enum DlMediaResolveStatus { loading, available, empty, error, unavailable }

class DlMediaSourceResult {
  const DlMediaSourceResult({
    required this.descriptor,
    required this.status,
    this.index,
    this.message,
  });

  final DlMediaSourceDescriptor descriptor;
  final DlMediaResolveStatus status;
  final FileNodeLibraryIndex? index;
  final String? message;

  bool get isVisible => index != null;

  DlMediaSourceResult copyWith({
    DlMediaResolveStatus? status,
    FileNodeLibraryIndex? index,
    bool clearIndex = false,
    String? message,
    bool clearMessage = false,
  }) {
    return DlMediaSourceResult(
      descriptor: descriptor,
      status: status ?? this.status,
      index: clearIndex ? null : index ?? this.index,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class DlMediaAggregationState {
  const DlMediaAggregationState({
    this.sources = const [],
    this.selectedKey,
    this.isRefreshingAll = false,
  });

  final List<DlMediaSourceResult> sources;
  final DlMediaSourceKey? selectedKey;
  final bool isRefreshingAll;

  List<DlMediaSourceResult> get visibleSources =>
      sources.where((source) => source.isVisible).toList(growable: false);

  DlMediaSourceResult? get selectedSource {
    for (final source in visibleSources) {
      if (source.descriptor.key == selectedKey) return source;
    }
    return visibleSources.firstOrNull;
  }

  bool get hasLoading =>
      sources.any((source) => source.status == DlMediaResolveStatus.loading);

  DlMediaAggregationState copyWith({
    List<DlMediaSourceResult>? sources,
    DlMediaSourceKey? selectedKey,
    bool clearSelectedKey = false,
    bool? isRefreshingAll,
  }) {
    return DlMediaAggregationState(
      sources: sources ?? this.sources,
      selectedKey: clearSelectedKey ? null : selectedKey ?? this.selectedKey,
      isRefreshingAll: isRefreshingAll ?? this.isRefreshingAll,
    );
  }
}
