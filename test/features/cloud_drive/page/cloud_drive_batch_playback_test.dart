import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai/features/cloud_drive/data/cloud_drive_source.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_page_result.dart';
import 'package:kikoenai/features/cloud_drive/page/cloud_drive_browser_page.dart';
import 'package:kikoenai/features/cloud_drive/provider/cloud_drive_source_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  for (final confirm in [true, false]) {
    testWidgets(
      'batch playback keeps the cloud branch when ${confirm ? 'confirmed' : 'canceled'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final source = _BatchCloudSource();
        final player = _BatchPlayer();
        final branchObserver = _PopObserver();
        final router = GoRouter(
          initialLocation: '/cloud',
          observers: [KikoenaiDialog.observer],
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => Scaffold(body: shell),
              branches: [
                StatefulShellBranch(
                  observers: [branchObserver],
                  routes: [
                    GoRoute(
                      path: '/cloud',
                      builder: (_, __) => const CloudDriveBrowserPage(
                        mode: CloudDriveMode.alistApi,
                        embedded: true,
                        isRoot: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cloudDriveSourceProvider.overrideWith((ref, mode) => source),
              parsedWorkIdsProvider.overrideWithValue(const <int>{}),
              playerControllerProvider.overrideWith(() => player),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('album'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('加入播放'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('正在收集媒体'), findsOneWidget);

        source.collection.complete(
          CloudDrivePageResult(
            items: [_node('/album/track.mp3', NodeType.audio)],
            totalCount: 1,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(branchObserver.popCount, 0);
        expect(find.text('正在收集媒体'), findsNothing);
        expect(find.text('加入播放队列'), findsOneWidget);
        expect(find.byType(CloudDriveBrowserPage), findsOneWidget);

        await tester.tap(find.text(confirm ? '加入' : '取消'));
        await tester.pumpAndSettle();
        expect(
          player.added.map((item) => item.title),
          confirm ? ['track.mp3'] : isEmpty,
        );
        expect(find.text('加入播放'), confirm ? findsNothing : findsOneWidget);
        expect(find.text('album'), findsOneWidget);
        expect(branchObserver.popCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _PopObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
  }
}

class _BatchPlayer extends PlayerController {
  final added = <PlaybackItem>[];

  @override
  AppPlayerState build() => const AppPlayerState();

  @override
  Future<void> addPlaybackItems(List<PlaybackItem> items) async {
    added.addAll(items);
  }
}

class _BatchCloudSource implements CloudDriveSource {
  final collection = Completer<CloudDrivePageResult>();

  @override
  String get id => 'batch-test';
  @override
  String get label => 'Batch test';
  @override
  NodeSource get nodeSource => NodeSource.cloudDrive;
  @override
  bool get supportsRemoteSearch => false;
  @override
  bool get supportsPagination => false;

  @override
  Future<CloudDrivePageResult> list({
    required String path,
    required int page,
    required int pageSize,
  }) async {
    if (path == '/album') return collection.future;
    return CloudDrivePageResult(
      items: [_node('/album', NodeType.folder)],
      totalCount: 1,
    );
  }

  @override
  Future<CloudDrivePageResult> search({
    required String path,
    required String query,
    required int scope,
    required int page,
    required int pageSize,
  }) async => const CloudDrivePageResult(items: [], totalCount: 0);

  @override
  String describeError(Object error) => error.toString();
}

FileNode _node(String path, NodeType type) => FileNode(
  type: type,
  title: NodeFolder(path).name,
  path: path,
  remoteId: path,
  mediaStreamUrl: 'https://media.example.com$path',
  source: NodeSource.cloudDrive,
);
