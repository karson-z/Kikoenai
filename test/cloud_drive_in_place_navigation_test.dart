import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/cloud_drive/page/cloud_drive_browser_page.dart';
import 'package:kikoenai/features/cloud_drive/provider/cloud_drive_source_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  testWidgets('folder navigation updates content without pushing a page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final source = _FakeCloudDriveSource();
    final observer = _PushCountingObserver();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudDriveSourceProvider.overrideWith((ref, mode) => source),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(
            body: CloudDriveBrowserPage(
              mode: CloudDriveMode.alistApi,
              isRoot: true,
              embedded: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialPushCount = observer.pushCount;
    expect(find.text('folder'), findsOneWidget);

    await tester.tap(find.text('folder'));
    await tester.pumpAndSettle();

    expect(observer.pushCount, initialPushCount);
    expect(source.requestedPaths, ['/', '/folder']);
    expect(find.text('track.mp3'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cloud_drive_alistApi_/folder')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('返回上一级'));
    await tester.pumpAndSettle();

    expect(observer.pushCount, initialPushCount);
    expect(find.text('folder'), findsOneWidget);
    expect(source.requestedPaths, ['/', '/folder']);

    await tester.tap(find.byTooltip('刷新'));
    await tester.pumpAndSettle();
    expect(source.requestedPaths, ['/', '/folder', '/']);
  });

  testWidgets('back restores the cached parent directory scroll position', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final source = _FakeCloudDriveSource(
      rootItems: [
        ...List.generate(30, (index) => _audio('/track-$index.mp3')),
        _folder('/folder'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudDriveSourceProvider.overrideWith((ref, mode) => source),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CloudDriveBrowserPage(
              mode: CloudDriveMode.alistApi,
              isRoot: true,
              embedded: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollController = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    for (var i = 0; i < 10 && find.text('folder').evaluate().isEmpty; i++) {
      scrollController.jumpTo(
        (scrollController.offset + 500).clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        ),
      );
      await tester.pump();
    }
    expect(find.text('folder'), findsOneWidget);
    final savedOffset = scrollController.offset;
    expect(savedOffset, greaterThan(0));

    await tester.tap(find.text('folder'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(scrollController.offset, closeTo(savedOffset, 1));
    expect(source.requestedPaths, ['/', '/folder']);
  });
}

class _PushCountingObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

class _FakeCloudDriveSource implements CloudDriveSource {
  _FakeCloudDriveSource({this.rootItems});

  final List<FileNode>? rootItems;
  final requestedPaths = <String>[];

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  NodeSource get nodeSource => NodeSource.cloudDrive;

  @override
  bool get supportsPagination => false;

  @override
  bool get supportsRemoteSearch => false;

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    requestedPaths.add(path);
    final items = path == '/'
        ? rootItems ?? [_folder('/folder')]
        : [_audio('/folder/track.mp3')];
    return CloudDrivePageResult(items: items, totalCount: items.length);
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async => const CloudDrivePageResult(items: [], totalCount: 0);

  @override
  String describeError(Object error) => error.toString();
}

FileNode _folder(String path) => FileNode(
  type: NodeType.folder,
  title: 'folder',
  path: path,
  remoteId: path,
  source: NodeSource.cloudDrive,
);

FileNode _audio(String path) => FileNode(
  type: NodeType.audio,
  title: NodeFolder(path).name,
  path: path,
  remoteId: path,
  source: NodeSource.cloudDrive,
);
