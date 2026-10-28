import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/proxy/auto_proxy_service.dart';
import 'package:kikoenai/core/service/proxy/proxy_settings.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/settings/page/proxy_settings_page.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('kikoenai_proxy_page_');
    Hive.init(directory.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });

  tearDown(() async {
    ProxyService.dispose();
    await AppStorage.settingsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('requires a valid address and fits a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));
    await tester.tap(find.text('保存并测试'));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效的 http://host:port 或 host:port'), findsOneWidget);
    expect(ProxySettings.fromStorage(AppStorage.settingsBox).isActive, isFalse);
    expect(AppStorage.settingsBox.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabling a tested proxy preserves its address for re-enabling',
    (tester) async {
      const saved = ProxySettings(
        enabled: true,
        configured: true,
        url: '127.0.0.1:7890',
      );
    await tester.runAsync(() => saved.save(AppStorage.settingsBox));
      ProxyService.setManualSettings(saved);
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));
      expect(find.text(saved.url), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      await tester.runAsync(() async {
        final changed = ProxyService.changes.first;
        await tester.tap(find.byType(SwitchListTile));
        await changed;
      });
      await tester.pumpAndSettle();
      final disabled = ProxySettings.fromStorage(AppStorage.settingsBox);
      expect(disabled.enabled, isFalse);
      expect(disabled.configured, isTrue);
      expect(disabled.url, saved.url);
      expect(ProxyService.manualSettings.isActive, isFalse);

      await tester.runAsync(() async {
        final changed = ProxyService.changes.first;
        await tester.tap(find.byType(SwitchListTile));
        await changed;
      });
      await tester.pumpAndSettle();
      expect(
        ProxySettings.fromStorage(AppStorage.settingsBox).isActive,
        isTrue,
      );
      expect(ProxyService.manualSettings.isActive, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
