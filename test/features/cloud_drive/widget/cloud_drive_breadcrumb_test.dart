import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_breadcrumb.dart';

void main() {
  testWidgets('renders borderless and stays pinned while content scrolls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(261, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              SliverPersistentHeader(
                pinned: true,
                delegate: CloudDriveBreadcrumbHeaderDelegate(
                  segments: const ['音乐', '收藏'],
                  onHomeTap: () {},
                  onSegmentTap: (_) {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 800)),
            ],
          ),
        ),
      ),
    );

    final bar = tester.widget<BreadcrumbBar>(find.byType(BreadcrumbBar));
    expect(bar.backgroundColor, Colors.transparent);
    expect(bar.borderColor, Colors.transparent);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byType(CloudDriveBreadcrumb)).dy,
      closeTo(0, 0.1),
    );
  });
}
