import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/local_media/widget/status_pill.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:riverpod/misc.dart' show Override;

FileNode _folder(String title, int? workId) {
  return FileNode(
    type: NodeType.folder,
    title: title,
    path: '/media/$title',
    workId: workId,
    source: NodeSource.cloudDrive,
  );
}

FileNode _file(String title) {
  return FileNode(
    type: NodeType.audio,
    title: title,
    path: '/media/$title',
    workId: 1231231,
    nodeStatus: NodeStatus.parsed,
    source: NodeSource.cloudDrive,
  );
}

Future<void> _pumpBrowser(
  WidgetTester tester, {
  required List<FileNode> nodes,
  required Set<int> parsedWorkIds,
  List<Override> overrides = const [],
  bool showFileMeta = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        parsedWorkIdsProvider.overrideWithValue(parsedWorkIds),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              FileNodeBrowser(
                currentNodes: nodes,
                work: null,
                source: NodeSource.cloudDrive,
                config: FileBrowserConfig(
                  showFolderStatus: true,
                  showFileMetaInfo: showFileMeta,
                ),
                onEnterFolder: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows no status when a folder has no RJ code', (tester) async {
    await _pumpBrowser(
      tester,
      nodes: [_folder('普通文件夹', null)],
      parsedWorkIds: const {},
    );

    expect(find.byType(NodeStatusPill), findsNothing);
  });

  testWidgets('shows pending until the RJ code exists in the library', (
    tester,
  ) async {
    await _pumpBrowser(
      tester,
      nodes: [_folder('[RJ01231231]', 1231231)],
      parsedWorkIds: const {},
    );

    expect(find.text('待解析'), findsOneWidget);
  });

  testWidgets('shows parsed when the RJ code exists in the library', (
    tester,
  ) async {
    await _pumpBrowser(
      tester,
      nodes: [_folder('[RJ01231231]', 1231231)],
      parsedWorkIds: const {1231231},
    );

    expect(find.text('已解析'), findsOneWidget);
  });

  testWidgets('shows the status pill in a cloud drive folder subtitle', (
    tester,
  ) async {
    await _pumpBrowser(
      tester,
      nodes: [_folder('[RJ01231231]', 1231231)],
      parsedWorkIds: const {1231231},
      showFileMeta: true,
    );

    expect(find.text('RJ01231231'), findsOneWidget);
    expect(find.text('已解析'), findsOneWidget);
  });

  testWidgets('shows parsing while the work is in the active queue', (
    tester,
  ) async {
    await _pumpBrowser(
      tester,
      nodes: [_folder('[RJ01231231]', 1231231)],
      parsedWorkIds: const {1231231},
      overrides: [
        scraperQueueProvider.overrideWith(
          () => _FixedQueue(
            ScraperQueueState(
              processing: [
                FileNode(
                  type: NodeType.folder,
                  title: '[RJ01231231]',
                  workId: 1231231,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    expect(find.text('解析中'), findsOneWidget);
  });

  testWidgets('does not show a status on a file row', (tester) async {
    await _pumpBrowser(
      tester,
      nodes: [_file('RJ01231231.mp3')],
      parsedWorkIds: const {1231231},
    );

    expect(find.byType(NodeStatusPill), findsNothing);
  });
}

class _FixedQueue extends ScraperQueueNotifier {
  _FixedQueue(this._fixed);

  final ScraperQueueState _fixed;

  @override
  ScraperQueueState build() => _fixed;
}
