import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';

void main() {
  Widget buildBreadcrumb({
    required List<String> paths,
    required ValueChanged<int> onPathTap,
    VoidCallback? onHomeTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BreadcrumbBar(
          paths: paths,
          onPathTap: onPathTap,
          onHomeTap: onHomeTap ?? () {},
        ),
      ),
    );
  }

  testWidgets(
    'shows shallow paths inline and keeps the current path disabled',
    (tester) async {
      final tappedIndexes = <int>[];

      await tester.pumpWidget(
        buildBreadcrumb(
          paths: const ['音乐', '收藏'],
          onPathTap: tappedIndexes.add,
        ),
      );

      expect(find.byKey(const ValueKey('breadcrumb-overflow')), findsNothing);
      expect(find.text('音乐'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);

      await tester.tap(find.text('音乐'));
      await tester.tap(find.text('收藏'));

      expect(tappedIndexes, [0]);
    },
  );

  testWidgets('collapses older paths into an indexed dropdown', (tester) async {
    final tappedIndexes = <int>[];
    var homeTapCount = 0;

    await tester.pumpWidget(
      buildBreadcrumb(
        paths: const ['文档', '主题', 'Github', '组件', '面包屑'],
        onPathTap: tappedIndexes.add,
        onHomeTap: () => homeTapCount++,
      ),
    );

    expect(find.text('文档'), findsNothing);
    expect(find.text('主题'), findsNothing);
    expect(find.text('Github'), findsNothing);
    expect(find.text('组件'), findsOneWidget);
    expect(find.text('面包屑'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('主题'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('breadcrumb-home')));

    expect(tappedIndexes, [1]);
    expect(homeTapCount, 1);
  });
}
