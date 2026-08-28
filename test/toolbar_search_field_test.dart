import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/common/search_field_style.dart';
import 'package:kikoenai/core/widgets/common/toolbar_search_field.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_toolbar.dart';
import 'package:kikoenai/features/dl_page/widget/dl_library_toolbar.dart';
import 'package:kikoenai/features/local_media/widget/local_media_toolbar.dart';

void main() {
  testWidgets('media toolbars reuse the shared search field', (tester) async {
    final controllers = List.generate(3, (_) => TextEditingController());
    final focusNodes = List.generate(3, (_) => FocusNode());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
      for (final focusNode in focusNodes) {
        focusNode.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CloudDriveToolbar(
                isRoot: true,
                isLoading: false,
                usesRemoteSearch: true,
                searchController: controllers[0],
                searchFocusNode: focusNodes[0],
                scope: CloudDriveScope.all,
                sort: CloudDriveSort.defaultSort,
                onBack: () {},
                onRefresh: () {},
                onSearchChanged: (_) {},
                onSearchSubmitted: (_) {},
                onClearSearch: controllers[0].clear,
                onScopeChanged: (_) {},
                onSortChanged: (_) {},
              ),
              LocalMediaToolbar(
                isRoot: true,
                isScanning: false,
                searchController: controllers[1],
                searchFocusNode: focusNodes[1],
                onBack: () {},
                onManagePaths: () {},
                onRefresh: () {},
                onSearchChanged: (_) {},
                onClearSearch: controllers[1].clear,
                onSort: () {},
              ),
              DlLibraryToolbar(
                searchController: controllers[2],
                searchFocusNode: focusNodes[2],
                isEditing: false,
                hasWorks: true,
                onSearchChanged: (_) {},
                onClearSearch: controllers[2].clear,
                onToggleEditing: () {},
                onClearAll: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ToolbarSearchField), findsNWidgets(3));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'search text stays visible in ${brightness.name} mode',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        final colorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorScheme: colorScheme, brightness: brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 165,
                  child: ToolbarSearchField(
                    controller: controller,
                    focusNode: focusNode,
                    hintText: '搜索',
                    onChanged: (_) {},
                    onClear: controller.clear,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), '测试内容');
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        final border = field.decoration!.border! as OutlineInputBorder;
        final expectedTextColor = brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF333333);
        expect(field.style!.color, expectedTextColor);
        expect(field.style!.color, isNot(field.decoration!.fillColor));
        expect(field.style!.inherit, isFalse);
        expect(field.style!.fontSize, 14);
        expect(field.style!.textBaseline, TextBaseline.alphabetic);
        expect(field.style!.height, 1);
        expect(field.textAlignVertical, TextAlignVertical.center);
        expect(
          border.borderRadius,
          BorderRadius.circular(appSearchBorderRadius),
        );
        expect(find.text('测试内容'), findsOneWidget);

        final fieldRect = tester.getRect(find.byType(TextField));
        final clearButtonRect = tester.getRect(find.byTooltip('清空搜索'));
        expect(clearButtonRect.size, const Size(32, 36));
        expect(clearButtonRect.right, closeTo(fieldRect.right, 0.1));
      },
    );
  }
}
