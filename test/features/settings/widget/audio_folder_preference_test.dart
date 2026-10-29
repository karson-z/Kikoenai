import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/settings/widget/audio_folder_preference_sheet.dart';

Future<void> _dragRow(WidgetTester tester, Finder from, Finder to) async {
  final start = tester.getCenter(from);
  final end = tester.getCenter(to);
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.moveTo(end);
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'kikoenai_audio_folder_sheet_',
    );
    Hive.init(hiveDirectory.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  tearDown(() async {
    await AppStorage.settingsBox.clear();
  });

  testWidgets('settings sheet reorders both tables', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AudioFolderPreferenceSheet(settingsBox: AppStorage.settingsBox),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('mp3'), findsOneWidget);
    expect(find.text('无音效'), findsOneWidget);
    final handles = find.byIcon(Icons.drag_handle);
    await _dragRow(tester, handles.at(0), handles.at(1));

    expect(AppStorage.settingsBox.get(StorageKeys.audioFormatPreference), [
      'wav',
      'mp3',
      'flac',
      'aac',
      'm4a',
      'ogg',
      'opus',
      'wma',
    ]);

    final effectRow = find.ancestor(
      of: find.text('有音效'),
      matching: find.byType(ListTile),
    );
    await _dragRow(tester, effectRow, find.text('无音效'));
    expect(AppStorage.settingsBox.get(StorageKeys.audioEffectPreference), [
      'with',
      'without',
    ]);
  });
}
