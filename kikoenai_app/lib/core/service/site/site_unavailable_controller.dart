import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SiteUnavailableIncident {
  const SiteUnavailableIncident({
    required this.siteId,
    required this.serverIds,
    required this.occurredAt,
    this.returnLocation,
    this.returnExtra,
  });

  final String siteId;
  final List<String> serverIds;
  final DateTime occurredAt;
  final String? returnLocation;
  final Object? returnExtra;

  SiteUnavailableIncident copyWith({
    String? returnLocation,
    Object? returnExtra,
  }) {
    return SiteUnavailableIncident(
      siteId: siteId,
      serverIds: serverIds,
      occurredAt: occurredAt,
      returnLocation: returnLocation ?? this.returnLocation,
      returnExtra: returnExtra ?? this.returnExtra,
    );
  }
}

class SiteUnavailableController extends ChangeNotifier {
  SiteUnavailableIncident? _incident;

  SiteUnavailableIncident? get incident => _incident;

  void report({required String siteId, required Iterable<String> serverIds}) {
    final previousReturnLocation = _incident?.siteId == siteId
        ? _incident?.returnLocation
        : null;
    final previousReturnExtra = _incident?.siteId == siteId
        ? _incident?.returnExtra
        : null;
    _incident = SiteUnavailableIncident(
      siteId: siteId,
      serverIds: List.unmodifiable(serverIds),
      occurredAt: DateTime.now(),
      returnLocation: previousReturnLocation,
      returnExtra: previousReturnExtra,
    );
    notifyListeners();
  }

  void captureReturnLocation(String location, {Object? extra}) {
    final current = _incident;
    if (current == null || current.returnLocation != null) return;
    _incident = current.copyWith(returnLocation: location, returnExtra: extra);
  }

  void clear() {
    if (_incident == null) return;
    _incident = null;
    notifyListeners();
  }
}

final siteUnavailableController = SiteUnavailableController();

final siteUnavailableControllerProvider = Provider<SiteUnavailableController>(
  (ref) => siteUnavailableController,
);
