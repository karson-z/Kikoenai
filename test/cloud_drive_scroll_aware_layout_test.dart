import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_scroll_aware_layout.dart';

void main() {
  testWidgets('reveals toolbar only after reverse scroll crosses threshold', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudDriveScrollAwareLayout(
            toolbar: const SizedBox(height: 44),
            child: CustomScrollView(
              controller: scrollController,
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 1000)),
              ],
            ),
          ),
        ),
      ),
    );

    final toolbarViewport = find.byKey(
      const ValueKey('scroll-aware-toolbar-viewport'),
    );
    expect(tester.getSize(toolbarViewport).height, 44);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(200));
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 24));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(200));
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 56));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(100));
    expect(tester.getSize(toolbarViewport).height, closeTo(44, 0.1));
    expect(tester.takeException(), isNull);
  });
}
