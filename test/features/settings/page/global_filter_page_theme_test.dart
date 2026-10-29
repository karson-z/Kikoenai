import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/theme/app_theme.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/features/settings/page/global_filter_page.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _TestGlobalFilterNotifier extends SearchFilterNotifier {
  _TestGlobalFilterNotifier() : super(FilterModule.global);

  @override
  SearchFilterState build() => const SearchFilterState();
}

void main() {
  Future<void> pumpPage(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchFilterProvider(
            FilterModule.global,
          ).overrideWith(_TestGlobalFilterNotifier.new),
        ],
        child: MaterialApp(theme: theme, home: const GlobalFilterTagsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AppBar follows light and dark themes', (tester) async {
    final lightTheme = AppTheme.light(Colors.blue);
    await pumpPage(tester, lightTheme);

    var appBar = tester.widget<AppBar>(find.byType(AppBar));
    var title = tester.widget<Text>(find.text('全局筛选'));
    expect(appBar.backgroundColor, lightTheme.appBarTheme.backgroundColor);
    expect(title.style?.color, lightTheme.colorScheme.onSurface);

    final darkTheme = AppTheme.dark(Colors.blue);
    await pumpPage(tester, darkTheme);

    appBar = tester.widget<AppBar>(find.byType(AppBar));
    title = tester.widget<Text>(find.text('全局筛选'));
    expect(appBar.backgroundColor, darkTheme.appBarTheme.backgroundColor);
    expect(title.style?.color, darkTheme.colorScheme.onSurface);
  });
}
