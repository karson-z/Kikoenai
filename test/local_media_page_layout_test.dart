import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_breadcrumb_header.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/features/local_media/page/local_media_page.dart';
import 'package:kikoenai/features/local_media/provider/file_scanner_notifier.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  testWidgets('uses cloud-style chrome and updates only the content area', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fileScannerProvider.overrideWith(_TestFileScannerNotifier.new),
        ],
        child: const MaterialApp(home: ScannerPage()),
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
  source: NodeSource.localSingle,
);

final _track = FileNode(
  type: NodeType.audio,
  title: 'track.mp3',
  path: '/root/folder/track.mp3',
  mediaStreamUrl: '/root/folder/track.mp3',
  remoteId: '/root/folder/track.mp3',
  source: NodeSource.localSingle,
);
