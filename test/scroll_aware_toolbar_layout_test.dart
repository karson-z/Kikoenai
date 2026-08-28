import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';

void main() {
  testWidgets('responds to vertical scrolling inside a nested scroll view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const innerScrollKey = ValueKey('nested-scroll-content');
    const markerKey = ValueKey('nested-scroll-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollAwareToolbarLayout(
            notificationPredicate: (_) => true,
            toolbar: const SizedBox(height: 80),
            child: NestedScrollView(
              headerSliverBuilder: (_, __) => const [],
              body: const CustomScrollView(
                key: innerScrollKey,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(key: markerKey, height: 1000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final toolbarViewport = find.byKey(
      const ValueKey('scroll-aware-toolbar-viewport'),
    );
    expect(tester.getSize(toolbarViewport).height, 80);

    await tester.drag(find.byKey(innerScrollKey), const Offset(0, -300));
    await tester.pumpAndSettle();

    final scrollable = Scrollable.of(tester.element(find.byKey(markerKey)));
    expect(scrollable.position.pixels, greaterThan(200));
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    final shortDrag = await tester.startGesture(
      tester.getCenter(find.byKey(innerScrollKey)),
    );
    await shortDrag.moveBy(const Offset(0, 24));
    await tester.pump();

    final partialHeight = tester.getSize(toolbarViewport).height;
    expect(partialHeight, greaterThan(0));
    expect(partialHeight, lessThan(40));

    await shortDrag.up();
    await tester.pumpAndSettle();

    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    final revealDrag = await tester.startGesture(
      tester.getCenter(find.byKey(innerScrollKey)),
    );
    await revealDrag.moveBy(const Offset(0, 56));
    await tester.pump();
    expect(tester.getSize(toolbarViewport).height, greaterThan(40));
    expect(tester.getSize(toolbarViewport).height, lessThan(80));

    await revealDrag.up();
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(200));
    expect(tester.getSize(toolbarViewport).height, closeTo(80, 0.1));

    final shortCollapse = await tester.startGesture(
      tester.getCenter(find.byKey(innerScrollKey)),
    );
    await shortCollapse.moveBy(const Offset(0, -24));
    await tester.pump();
    expect(tester.getSize(toolbarViewport).height, greaterThan(40));
    expect(tester.getSize(toolbarViewport).height, lessThan(80));

    await shortCollapse.up();
    await tester.pumpAndSettle();

    expect(tester.getSize(toolbarViewport).height, closeTo(80, 0.1));

    final collapseDrag = await tester.startGesture(
      tester.getCenter(find.byKey(innerScrollKey)),
    );
    await collapseDrag.moveBy(const Offset(0, -56));
    await tester.pump();
    expect(tester.getSize(toolbarViewport).height, greaterThan(0));
    expect(tester.getSize(toolbarViewport).height, lessThan(40));

    await collapseDrag.up();
    await tester.pumpAndSettle();

    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps toolbar visible while visibility is forced', (
    tester,
  ) async {
    var forceVisible = false;
    late StateSetter updateLayout;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateLayout = setState;
              return ScrollAwareToolbarLayout(
                forceToolbarVisible: forceVisible,
                toolbar: const SizedBox(height: 80),
                child: const CustomScrollView(
                  slivers: [SliverToBoxAdapter(child: SizedBox(height: 1000))],
                ),
              );
            },
          ),
        ),
      ),
    );

    final toolbarViewport = find.byKey(
      const ValueKey('scroll-aware-toolbar-viewport'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    updateLayout(() => forceVisible = true);
    await tester.pumpAndSettle();
    expect(tester.getSize(toolbarViewport).height, 80);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getSize(toolbarViewport).height, 80);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves toolbar visibility across parent rebuilds', (
    tester,
  ) async {
    var revision = 0;
    late StateSetter rebuildLayout;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuildLayout = setState;
              return ScrollAwareToolbarLayout(
                toolbar: SizedBox(height: 80, child: Text('$revision')),
                child: const CustomScrollView(
                  slivers: [SliverToBoxAdapter(child: SizedBox(height: 1000))],
                ),
              );
            },
          ),
        ),
      ),
    );

    final toolbarViewport = find.byKey(
      const ValueKey('scroll-aware-toolbar-viewport'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));

    rebuildLayout(() => revision++);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(tester.getSize(toolbarViewport).height, closeTo(0, 0.1));
    expect(tester.takeException(), isNull);
  });
}
