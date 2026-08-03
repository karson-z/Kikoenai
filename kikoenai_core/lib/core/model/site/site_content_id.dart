/// Identifies remote content without assuming a site's IDs are numeric.
class SiteContentId {
  const SiteContentId({required this.siteId, required this.remoteId})
    : assert(siteId != ''),
      assert(remoteId != '');

  /// Site used by data created before multi-site identity was introduced.
  static const String legacySiteId = 'asmr.one';

  final String siteId;
  final String remoteId;

  String get storageKey =>
      '${Uri.encodeComponent(siteId)}:${Uri.encodeComponent(remoteId)}';

  Uri get uri =>
      Uri(scheme: 'kikoenai-site', host: siteId, pathSegments: [remoteId]);

  static SiteContentId? tryParseUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null ||
        parsed.scheme != 'kikoenai-site' ||
        parsed.host.isEmpty ||
        parsed.pathSegments.length != 1 ||
        parsed.pathSegments.first.isEmpty) {
      return null;
    }
    return SiteContentId(
      siteId: parsed.host,
      remoteId: parsed.pathSegments.first,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SiteContentId &&
      other.siteId == siteId &&
      other.remoteId == remoteId;

  @override
  int get hashCode => Object.hash(siteId, remoteId);

  @override
  String toString() => '$siteId:$remoteId';
}
