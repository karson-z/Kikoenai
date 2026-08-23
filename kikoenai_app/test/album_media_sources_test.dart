import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/features/album/widget/album_file_section.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_option.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _FakeMediaSiteApi extends SiteApi {
  _FakeMediaSiteApi(this.features);

  final Set<SiteFeature> features;
  final List<String> trackRequests = [];

  @override
  Set<SiteFeature> get supportedFeatures => features;

  @override
  Future<List<FileNode>> getWorkTracks(String workId) async {
    trackRequests.add(workId);
    return [
      FileNode(
        type: NodeType.audio,
        title: 'track.mp3',
        hash: 'track-$workId',
        mediaStreamUrl: 'https://example.test/$workId/track.mp3',
      ),
    ];
  }
}

class _TestFileSortNotifier extends FileSortNotifier {
  @override
  FileSortOption build() => FileSortOption.defaultOption;
}

SiteRuntime _runtime(String id, String name, SiteApi api) {
  return SiteRuntime.fromApi(
    info: SiteInfo(id: id, name: name, version: '1.0.0'),
    api: api,
  );
}

void main() {
  testWidgets('detail reads media only from the active site', (tester) async {
    final tracksApi = _FakeMediaSiteApi({SiteFeature.tracks});
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('tracks.site', 'Tracks', tracksApi));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('tracks.site'),
          fileSortProvider.overrideWith(_TestFileSortNotifier.new),
          explicitDarkModeProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [AlbumMediaSourceSection(work: Work(id: 1002500))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('track.mp3'), findsOneWidget);
    expect(tracksApi.trackRequests, ['1002500']);
  });

  testWidgets('detail rejects file-system-only active sites', (tester) async {
    final api = _FakeMediaSiteApi({
      SiteFeature.fileSystemSearch,
      SiteFeature.fileSystemBrowse,
    });
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('filesystem.site', 'File system', api));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siteRegistryProvider.overrideWithValue(registry),
          initialActiveSiteIdProvider.overrideWithValue('filesystem.site'),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [AlbumMediaSourceSection(work: Work(id: 1002500))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前站点不支持作品媒体'), findsOneWidget);
    expect(api.trackRequests, isEmpty);
  });
}
