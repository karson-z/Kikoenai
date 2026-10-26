import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  test('phone navigation and density survive rotation', () {
    final portrait = AppLayoutTokens.forWindow(
      const Size(390, 844),
      TargetPlatform.iOS,
    );
    final landscape = AppLayoutTokens.forWindow(
      const Size(844, 390),
      TargetPlatform.iOS,
    );
    final largePhone = AppLayoutTokens.forWindow(
      const Size(1080, 480),
      TargetPlatform.iOS,
    );
    for (final layout in [portrait, landscape, largePhone]) {
      expect(layout.isPhone, isTrue);
      expect(layout.useWideNavigation, isFalse);
      expect(layout.pageInset, 4);
      expect(layout.gridGap, 1);
      expect(layout.card(AppCardVariant.workList).margin.vertical, 1);
    }
    expect(landscape.size, AppLayoutSize.medium);
    expect(largePhone.size, AppLayoutSize.expanded);
    expect(portrait.searchToolbarHeight, 64);
    expect(landscape.searchToolbarHeight, 48);
  });

  test(
    'non-phone navigation uses 840 without changing density breakpoints',
    () {
      final narrow = AppLayoutTokens.forWindow(
        const Size(839, 390),
        TargetPlatform.macOS,
      );
      final wide = AppLayoutTokens.forWindow(
        const Size(840, 390),
        TargetPlatform.macOS,
      );
      expect(narrow.isPhone, isFalse);
      expect(narrow.useWideNavigation, isFalse);
      expect(wide.useWideNavigation, isTrue);
      expect(wide.pageInset, 8);
      expect(wide.gridGap, 12);
      final tablet = AppLayoutTokens.forWindow(
        const Size(1024, 768),
        TargetPlatform.iOS,
      );
      expect(tablet.isPhone, isFalse);
      expect(tablet.useWideNavigation, isTrue);
      expect(tablet.pageInset, 16);
    },
  );

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
      [4, 8, 16],
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
