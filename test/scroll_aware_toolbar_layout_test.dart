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

    final animatedToolbar = find.byType(AnimatedAlign);
    expect(tester.getSize(animatedToolbar).height, 80);

    await tester.drag(find.byKey(innerScrollKey), const Offset(0, -300));
    await tester.pumpAndSettle();

    final scrollable = Scrollable.of(tester.element(find.byKey(markerKey)));
    expect(scrollable.position.pixels, greaterThan(200));
    expect(tester.getSize(animatedToolbar).height, 0);

    await tester.drag(find.byKey(innerScrollKey), const Offset(0, 24));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(200));
    expect(tester.getSize(animatedToolbar).height, 80);
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

    final animatedToolbar = find.byType(AnimatedAlign);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(animatedToolbar).height, 0);

    updateLayout(() => forceVisible = true);
    await tester.pumpAndSettle();
    expect(tester.getSize(animatedToolbar).height, 80);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getSize(animatedToolbar).height, 80);
    expect(tester.takeException(), isNull);
  });
}
