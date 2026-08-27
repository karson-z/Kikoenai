import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_toolbar.dart';

void main() {
  testWidgets('keeps every root action in one compact row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(261, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final searchController = TextEditingController();
    final searchFocusNode = FocusNode();
    addTearDown(searchController.dispose);
    addTearDown(searchFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudDriveToolbar(
            isRoot: true,
            isLoading: false,
            usesRemoteSearch: true,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            scope: CloudDriveScope.all,
            sort: CloudDriveSort.defaultSort,
            onBack: () {},
            onRefresh: () {},
            onSearchChanged: (_) {},
            onSearchSubmitted: (_) {},
            onClearSearch: () {},
            onScopeChanged: (_) {},
            onSortChanged: (_) {},
            onManageSource: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.cloud_outlined), findsNothing);

    final controls = [
      find.byType(TextField),
      find.byIcon(Icons.settings_outlined),
      find.byIcon(Icons.refresh),
      find.byIcon(Icons.filter_alt_outlined),
      find.byIcon(Icons.sort),
    ];
    final centerY = tester.getCenter(controls.first).dy;
    for (final control in controls.skip(1)) {
      expect((tester.getCenter(control).dy - centerY).abs(), lessThan(2));
    }
  });
}
