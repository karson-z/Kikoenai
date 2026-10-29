import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/scroll/my_scroll_behavior.dart';

void main() {
  testWidgets('shows refresh indicator without displacing content on iOS', (
    tester,
  ) async {
    const contentKey = ValueKey('refresh-content');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {},
            child: const CustomScrollView(
              physics: nonBouncingRefreshScrollPhysics,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(key: contentKey, height: 1000),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final initialContentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
    final drag = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await drag.moveBy(const Offset(0, 80));
    await tester.pump();

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(contentKey)).dy, initialContentTop);

    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
