import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/dl_page/widget/dl_library_header.dart';
import 'package:kikoenai/features/dl_page/widget/dl_library_toolbar.dart';

void main() {
  testWidgets('DL library chrome stays compact on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var queueOpenCount = 0;
    var editCount = 0;
    var clearCount = 0;
    final searchController = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(searchController.dispose);
    addTearDown(searchFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DlLibraryHeader(
                queueCount: 3,
                onOpenQueue: () => queueOpenCount++,
              ),
              DlLibraryToolbar(
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                isEditing: true,
                hasWorks: true,
                onSearchChanged: (_) {},
                onClearSearch: searchController.clear,
                onToggleEditing: () => editCount++,
                onClearAll: () => clearCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('DL库'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('解析队列'));
    await tester.tap(find.byTooltip('全部清空'));
    await tester.tap(find.byTooltip('完成编辑'));
    expect((queueOpenCount, clearCount, editCount), (1, 1, 1));
  });
}
