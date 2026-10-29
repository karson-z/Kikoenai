import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_breadcrumb_header.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/local_media/page/local_media_page.dart';
import 'package:kikoenai/features/local_media/provider/file_scanner_notifier.dart';
import 'package:kikoenai/features/local_media/provider/local_media_exclusion_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  for (final height in [390.0, 320.0]) {
    testWidgets('empty library remains reachable in ${height}px landscape', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(844, height);
      tester.view.padding = const FakeViewPadding(left: 47, right: 47);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fileScannerProvider.overrideWith(_EmptyFileScannerNotifier.new),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(
              body: LocalMediaPage(),
              // Reserve the landscape mini-player, navigation and home inset.
              bottomNavigationBar: SizedBox(height: 48 + 48 + 21),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('这里空空如也'), findsOneWidget);
      await tester.ensureVisible(find.text('添加文件夹'));
      await tester.pumpAndSettle();
      expect(find.text('添加文件夹').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses cloud-style chrome and updates only the content area', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fileScannerProvider.overrideWith(_TestFileScannerNotifier.new),
          localMediaExclusionsProvider('/root').overrideWith((ref) => []),
          parsedWorkIdsProvider.overrideWithValue(const <int>{}),
        ],
        child: const MaterialApp(home: LocalMediaPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(ScrollAwareToolbarLayout), findsOneWidget);
    expect(find.byType(FileBreadcrumb), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('本地媒体'), findsOneWidget);
    expect(find.text('folder'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.text('没有匹配的文件'), findsOneWidget);

    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pump();
    expect(find.text('folder'), findsOneWidget);

    await tester.tap(find.text('folder'));
    await tester.pump();
    expect(find.text('track.mp3'), findsOneWidget);
    expect(find.byTooltip('返回上一级'), findsOneWidget);

    await tester.tap(find.byTooltip('返回上一级'));
    await tester.pump();
    expect(find.text('folder'), findsOneWidget);
    expect(find.text('本地媒体'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyFileScannerNotifier extends FileScannerNotifier {
  @override
  FileBrowserState build() => const FileBrowserState(
    rootPath: '',
    currentFolderPath: null,
    isHome: true,
  );
}

class _TestFileScannerNotifier extends FileScannerNotifier {
  @override
  FileBrowserState build() => FileBrowserState(
    rootPath: '/root',
    currentFolderPath: '/root',
    children: [_folder],
    isHome: true,
  );

  @override
  void stepIn(NodeFolder folder) {
    state = state.copyWith(
      currentFolderPath: folder.normalized,
      children: [_track],
      isHome: false,
    );
  }

  @override
  void stepOut() {
    state = state.copyWith(
      currentFolderPath: '/root',
      children: [_folder],
      isHome: true,
    );
  }

  @override
  Future<void> refreshCurrentTarget() async {}
}

final _folder = FileNode(
  type: NodeType.folder,
  title: 'folder',
  path: '/root/folder',
  remoteId: '/root/folder',
  source: NodeSource.local,
);

final _track = FileNode(
  type: NodeType.audio,
  title: 'track.mp3',
  path: '/root/folder/track.mp3',
  mediaStreamUrl: '/root/folder/track.mp3',
  remoteId: '/root/folder/track.mp3',
  source: NodeSource.local,
);
