import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_mode_switch.dart';

void main() {
  testWidgets('keeps the compact mode switch beside the title', (tester) async {
    await tester.binding.setSurfaceSize(const Size(261, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CloudDriveMode? selectedMode;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudDriveModeSwitch(
            value: CloudDriveMode.alistApi,
            onChanged: (mode) => selectedMode = mode,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final titleCenter = tester.getCenter(find.text('云盘'));
    final switchCenter = tester.getCenter(
      find.byType(SegmentedButton<CloudDriveMode>),
    );
    expect((titleCenter.dy - switchCenter.dy).abs(), lessThan(2));

    await tester.tap(find.text('WebDAV'));
    expect(selectedMode, CloudDriveMode.webDav);
  });
}
