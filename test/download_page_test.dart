import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/download/page/download_page.dart';
import 'package:kikoenai/features/download/provider/download_provider.dart';

class _TestAllTasksNotifier extends AllTasksNotifier {
  @override
  Future<List<TaskRecord>> build() async => const [];

  @override
  Future<void> refreshTasks() async {}
}

void main() {
  testWidgets('separates downloading and completed tasks into tab views', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [allTasksProvider.overrideWith(_TestAllTasksNotifier.new)],
        child: const MaterialApp(home: DownloadPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.text('下载中'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final indicator = tabBar.indicator! as BoxDecoration;
    expect(indicator.borderRadius, BorderRadius.circular(6));
    expect(indicator.boxShadow, isNull);
    final tabBackground = tester.widget<Container>(
      find.byKey(const ValueKey('download_tabs')),
    );
    expect(tabBackground.decoration, isA<BoxDecoration>());
    expect(tabBar.splashFactory, NoSplash.splashFactory);
    expect(
      tabBar.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(find.text('暂无下载任务'), findsOneWidget);
    expect(find.text('暂无历史记录'), findsNothing);
    final pageCenter = tester.getCenter(find.byType(TabBarView));
    final downloadingEmptyCenter = tester.getCenter(
      find.byKey(const ValueKey('downloading_empty_state')),
    );
    expect(downloadingEmptyCenter.dx, closeTo(pageCenter.dx, 0.1));
    expect(downloadingEmptyCenter.dy, closeTo(pageCenter.dy, 0.1));
    expect(find.byTooltip('全部开始'), findsOneWidget);
    expect(find.byTooltip('全部暂停'), findsOneWidget);

    await tester.tap(find.text('已完成'));
    await tester.pumpAndSettle();

    expect(find.text('暂无下载任务'), findsNothing);
    expect(find.text('暂无历史记录'), findsOneWidget);
    final completedEmptyCenter = tester.getCenter(
      find.byKey(const ValueKey('completed_empty_state')),
    );
    expect(completedEmptyCenter.dx, closeTo(pageCenter.dx, 0.1));
    expect(completedEmptyCenter.dy, closeTo(pageCenter.dy, 0.1));
    expect(find.byTooltip('全部开始'), findsNothing);
    expect(find.byTooltip('全部暂停'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
