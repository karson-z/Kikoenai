import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/local_media/widget/local_media_header.dart';
import 'package:kikoenai/features/local_media/widget/local_media_toolbar.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  testWidgets('header and toolbar stay compact on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(261, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var selectedMode = ScanMode.audio;
    var manageCount = 0;
    var refreshCount = 0;
    var sortCount = 0;
    final searchController = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(searchController.dispose);
    addTearDown(searchFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LocalMediaHeader(
                value: selectedMode,
                onChanged: (mode) => selectedMode = mode,
              ),
              LocalMediaToolbar(
                isRoot: true,
                isScanning: false,
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                onBack: () {},
                onManagePaths: () => manageCount++,
                onRefresh: () => refreshCount++,
                onSearchChanged: (_) {},
                onClearSearch: searchController.clear,
                onSort: () => sortCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('本地媒体'), findsOneWidget);

    await tester.tap(find.text('视频'));
    expect(selectedMode, ScanMode.video);

    await tester.tap(find.byTooltip('管理路径'));
    await tester.tap(find.byTooltip('同步媒体库'));
    await tester.tap(find.byTooltip('排序'));
    expect((manageCount, refreshCount, sortCount), (1, 1, 1));
  });
}
