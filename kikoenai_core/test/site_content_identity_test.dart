import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  test('non-numeric remote ID round-trips through its URI', () {
    const id = SiteContentId(siteId: 'site.example', remoteId: 'work/A-42');

    expect(SiteContentId.tryParseUri(id.uri.toString()), id);
    expect(id.remoteId, 'work/A-42');
  });

  test('work origin identity round-trips through JSON metadata', () {
    const work = Work(
      id: 42,
      title: 'Example',
      siteId: 'site.example',
      remoteId: 'work/A-42',
    );

    final json = work.toJson();
    final restored = Work.fromJson(json);

    expect(json['siteId'], 'site.example');
    expect(json['remoteId'], 'work/A-42');
    expect(restored.contentId, work.contentId);
  });

  test('playback media metadata retains the origin site', () {
    const item = PlaybackItem(
      id: 'track-1',
      url: 'https://example.test/track.mp3',
      title: 'Track',
      scopeId: 'album-A',
      siteId: 'site.example',
      remoteId: 'album-A',
    );

    final restored = PlaybackItem.fromMediaItem(item.toMediaItem());

    expect(restored.contentId, item.contentId);
  });

  test('legacy and site-aware history keys remain distinguishable', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    const legacyItem = PlaybackItem(
      id: 'legacy-track',
      url: 'https://example.test/legacy.mp3',
      title: 'Legacy',
      scopeId: '42',
      workId: 42,
    );
    const siteItem = PlaybackItem(
      id: 'new-track',
      url: 'https://example.test/new.mp3',
      title: 'New',
      scopeId: '42',
      workId: 42,
      siteId: 'site.example',
      remoteId: '42',
    );

    final legacy = HistoryEntry(
      session: PlaybackSession.fromQueue([legacyItem]),
      lastItemId: legacyItem.id,
      lastPlayTime: now,
    );
    final siteAware = HistoryEntry(
      session: PlaybackSession.fromQueue([siteItem]),
      lastItemId: siteItem.id,
      lastPlayTime: now,
    );

    expect(legacy.primaryKey, 'work_42');
    expect(siteAware.primaryKey, 'work_site.example:42');
  });
}
