import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import 'package:kikoenai/core/widgets/filter/inline/inline_filter.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/features/category/provider/category_option_provider.dart';
import 'package:kikoenai/features/category/widget/filter_header.dart';
import 'package:kikoenai/features/dl_page/widget/dl_library_toolbar.dart';
import 'package:kikoenai/features/dl_page/widget/parsed_works_view.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  testWidgets('filter dropdown panel keeps the site-backed default data source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          explicitDarkModeProvider.overrideWithValue(false),
          tagsProvider.overrideWith(
            (ref) async => const <Tag>[Tag(id: 999, name: '远程标签')],
          ),
          circlesProvider.overrideWith(
            (ref) async => const <Circle>[Circle(id: 999, name: '远程社团')],
          ),
          vasProvider.overrideWith(
            (ref) async => const <VA>[VA(id: 'remote', name: '远程声优')],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FilterDropdownPanel(module: FilterModule.category),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('筛选内容'), findsOneWidget);
    expect(find.text('远程标签'), findsOneWidget);
    expect(find.text('远程社团'), findsNothing);
  });

  testWidgets('DL library keeps the collapsed bar and opens the dropdown panel', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          explicitDarkModeProvider.overrideWithValue(false),
          availableSurfacesProvider.overrideWithValue(const <AppSurface>{}),
          tagsProvider.overrideWith(
            (ref) async => const <Tag>[Tag(id: 999, name: '远程标签')],
          ),
          circlesProvider.overrideWith(
            (ref) async => const <Circle>[Circle(id: 999, name: '远程社团')],
          ),
          vasProvider.overrideWith(
            (ref) async => const <VA>[VA(id: 'remote', name: '远程声优')],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ParseWorksView(
              work: [
                Work(
                  id: 1,
                  title: 'Alpha',
                  createDate: '2026-01-01',
                  circle: Circle(id: 1, name: '本地社团'),
                  tags: [Tag(id: 1, name: '本地标签')],
                  vas: [VA(id: 'local', name: '本地声优')],
                ),
                Work(
                  id: 2,
                  title: 'Beta',
                  createDate: '2026-02-01',
                  tags: [Tag(id: 1, name: '本地标签')],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ScrollAwareToolbarLayout), findsOneWidget);
    expect(find.byType(DlLibraryToolbar), findsOneWidget);
    expect(find.byType(FilterHeader), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(WorkCard), findsNWidgets(2));

    // 收起态：横条常驻页面布局，展示维度快捷入口（DL库选项来自本地聚合）
    expect(find.text('标签'), findsOneWidget);
    expect(find.byType(FilterDropdownPanel), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Alpha');
    await tester.pump();
    expect(find.byType(WorkCard), findsOneWidget);
    expect(find.text('Beta'), findsNothing);

    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pump();
    expect(find.byType(WorkCard), findsNWidgets(2));

    // 展开：面板从工具栏底部覆盖出现（横条仍在布局中，不压缩列表）
    await tester.tap(find.text('标签'));
    await tester.pumpAndSettle();

    final filterPanel = find.byType(FilterDropdownPanel);
    expect(filterPanel, findsOneWidget);
    // 收起横条仍存在于布局中（被面板覆盖）
    expect(find.byType(InlineFilterBar), findsOneWidget);
    // 作品列表未被压缩（两张卡片仍在树中，被遮罩盖住）
    expect(find.byType(WorkCard), findsNWidgets(2));
    // 全局模态遮罩存在
    expect(find.byType(ColoredBox), findsWidgets);

    expect(
      find.descendant(of: filterPanel, matching: find.text('本地标签')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: filterPanel, matching: find.text('远程标签')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: filterPanel, matching: find.text('社团')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: filterPanel, matching: find.text('本地社团')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: filterPanel, matching: find.text('远程社团')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: filterPanel, matching: find.text('声优')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: filterPanel, matching: find.text('本地声优')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: filterPanel, matching: find.text('远程声优')),
      findsNothing,
    );

    // 点击遮罩收起面板，横条恢复可见
    await tester.tap(find.byType(GestureDetector).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FilterDropdownPanel), findsNothing);
    expect(find.text('标签'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
