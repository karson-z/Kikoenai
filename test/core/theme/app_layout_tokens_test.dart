import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  group('AppLayoutTokens breakpoints', () {
    for (final scenario in [
      (width: 599.0, size: AppLayoutSize.compact),
      (width: 600.0, size: AppLayoutSize.medium),
      (width: 1023.0, size: AppLayoutSize.medium),
      (width: 1024.0, size: AppLayoutSize.expanded),
    ]) {
      testWidgets('${scenario.width} logical px uses ${scenario.size.name}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scenario.width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late AppLayoutTokens tokens;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: Builder(
                builder: (context) {
                  tokens = context.layout;
                  return child!;
                },
              ),
              breakpoints: const [
                Breakpoint(start: 0, end: 599, name: 'compact'),
                Breakpoint(start: 600, end: 1023, name: 'medium'),
                Breakpoint(start: 1024, end: double.infinity, name: 'expanded'),
              ],
            ),
            home: const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tokens.size, scenario.size);
      });
    }
  });

  test('layout tokens provide the documented density and card metrics', () {
    final compact = AppLayoutTokens.forSize(AppLayoutSize.compact);
    final medium = AppLayoutTokens.forSize(AppLayoutSize.medium);
    final expanded = AppLayoutTokens.forSize(AppLayoutSize.expanded);

    expect(
      [compact.pageInset, medium.pageInset, expanded.pageInset],
      [16, 24, 32],
    );
    expect([compact.gridGap, medium.gridGap, expanded.gridGap], [1, 12, 16]);
    expect(
      [compact.sectionGap, medium.sectionGap, expanded.sectionGap],
      [16, 24, 32],
    );
    expect(compact.card(AppCardVariant.workGrid).coverAspectRatio, 4 / 3);
    expect(medium.card(AppCardVariant.workList).coverSize, const Size(88, 66));
    expect(expanded.card(AppCardVariant.fileRow).radius, 4);
  });
}
