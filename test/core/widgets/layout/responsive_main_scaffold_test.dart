import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:kikoenai/config/navigation_item.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/core/widgets/common/global_search_input.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import 'package:kikoenai/core/widgets/layout/adaptive_app_bar_mobile.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/core/widgets/layout/navigation_rail.dart';
import 'package:kikoenai/features/album/widget/work_grid_layout.dart';
import 'package:kikoenai/features/cloud_drive/model/cloud_drive_mode.dart';
import 'package:kikoenai/features/cloud_drive/widget/cloud_drive_mode_switch.dart';
import 'package:kikoenai/features/dl_page/widget/dl_library_header.dart';
import 'package:kikoenai/features/local_media/widget/local_media_header.dart';
import 'package:kikoenai/features/player/page/player_view.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/player_lyrics_match_provider.dart';
import 'package:kikoenai/features/player/widget/audio/player_background.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _IdlePlayer extends PlayerController {
  @override
  AppPlayerState build() => const AppPlayerState();
}

class _ActivePlayer extends PlayerController {
  @override
  AppPlayerState build() => const AppPlayerState(
    playing: true,
    session: PlaybackSession(
      id: 'session',
      createdAt: 0,
      updatedAt: 0,
      queue: [
        PlaybackItem(
          id: 'sample',
          url: '/sample.mp3',
          title: 'Current track',
          scopeId: 'sample',
          source: NodeSource.local,
        ),
      ],
    ),
  );
}

class _NoLyrics extends LyricsMatchController {
  @override
  LyricsMatchState build() => const LyricsMatchState();
}

class _TestPage extends StatefulWidget {
  const _TestPage({required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPage> {
  final scroll = ScrollController();
  int count = 0;
  @override
  void initState() {
    super.initState();
    widget.onCreated();
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return Scaffold(
      appBar: layout.useWideNavigation
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(layout.searchToolbarHeight),
              child: const MobileSearchAppBar(),
            ),
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => count++),
            child: Text('count $count'),
          ),
          Expanded(
            child: ListView.builder(
              key: const Key('stateful-list'),
              controller: scroll,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (_, i) => Text('item $i'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<GoRouter> _mount(
  WidgetTester tester, {
  required Size size,
  required TargetPlatform platform,
  required VoidCallback onCreated,
  bool activePlayback = false,
  Widget Function(BuildContext, int)? pageBuilder,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainScaffold(navigationShell: shell),
        branches: [
          for (final item in appNavigationItems)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: item.routePath,
                  builder: (context, _) =>
                      pageBuilder?.call(context, item.branchIndex) ??
                      _TestPage(onCreated: onCreated),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const Scaffold(body: Text('Search destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerControllerProvider.overrideWith(
          activePlayback ? _ActivePlayer.new : _IdlePlayer.new,
        ),
        lyricsMatchControllerProvider.overrideWith(_NoLyrics.new),
        blurredImageProvider.overrideWith((ref) async => null),
        explicitDarkModeProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        theme: ThemeData(platform: platform),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('landscape page headers align with the home cards', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(
      left: 47,
      right: 47,
      bottom: 21,
    );
    tester.view.viewPadding = const FakeViewPadding(
      left: 47,
      right: 47,
      bottom: 21,
    );
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final router = await _mount(
      tester,
      size: const Size(844, 390),
      platform: TargetPlatform.iOS,
      onCreated: () {},
      pageBuilder: (context, index) {
        if (index == 0) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                ResponsiveCardGrid(
                  pagingState: PagingState<int, Work>(
                    pages: const [
                      [Work(id: 1, title: 'Alignment reference')],
                    ],
                    keys: const [1],
                    hasNextPage: false,
                  ),
                  fetchNextPage: () {},
                ),
              ],
            ),
          );
        }
        final header = switch (index) {
          2 => LocalMediaHeader(value: ScanMode.audio, onChanged: (_) {}),
          3 => CloudDriveModeSwitch(
            value: CloudDriveMode.alistApi,
            onChanged: (_) {},
          ),
          _ => DlLibraryHeader(queueCount: 0, onOpenQueue: () {}),
        };
        // These pages protect their content with a page-level SafeArea.
        return Scaffold(
          body: SafeArea(bottom: false, child: Column(children: [header])),
        );
      },
    );
    final homeCard = tester.getRect(find.byType(WorkCard));
    expect(homeCard.left, 47 + 4);
    for (final index in [2, 3, 4]) {
      router.go(appNavigationItems[index].routePath);
      await tester.pumpAndSettle();
      final header = find.byType(switch (index) {
        2 => LocalMediaHeader,
        3 => CloudDriveModeSwitch,
        _ => DlLibraryHeader,
      });
      final row = tester.getRect(
        find.descendant(of: header, matching: find.byType(Row)).first,
      );
      expect(row.left, homeCard.left);
      expect(row.right, 844 - 47 - 4);
      expect(MediaQuery.paddingOf(tester.element(header)).horizontal, 0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'phone player stays usable at 48px after rotation with safe areas',
    (tester) async {
      await _mount(
        tester,
        size: const Size(390, 844),
        platform: TargetPlatform.iOS,
        onCreated: () {},
        activePlayback: true,
      );
      final state = tester.state(find.byType(PlayerView));
      tester.view.physicalSize = const Size(844, 390);
      tester.view.padding = const FakeViewPadding(
        left: 47,
        right: 47,
        bottom: 21,
      );
      tester.view.viewPadding = const FakeViewPadding(
        left: 47,
        right: 47,
        bottom: 21,
      );
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(PlayerView)), same(state));
      expect(tester.widget<PlayerView>(find.byType(PlayerView)).minHeight, 48);
      expect(tester.getTopLeft(find.byType(PlayerView)).dx, 47);
      expect(tester.getSize(find.byType(PlayerView)).width, 750);
      expect(find.byTooltip('播放队列').hitTestable(), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets('playing session and expanded player survive navigation resize', (
    tester,
  ) async {
    await _mount(
      tester,
      size: const Size(839, 700),
      platform: TargetPlatform.macOS,
      onCreated: () {},
      activePlayback: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainScaffold)),
    );
    final playerState = tester.state(find.byType(PlayerView));
    final controller = container.read(panelControllerProvider);
    final session = container.read(playerControllerProvider).session;
    final playerNotifier = container.read(playerControllerProvider.notifier);
    for (final width in [840.0, 1440.0, 839.0]) {
      tester.view.physicalSize = Size(width, 700);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(PlayerView)), same(playerState));
      expect(
        container.read(playerControllerProvider.notifier),
        same(playerNotifier),
      );
      expect(container.read(playerControllerProvider).session, same(session));
      expect(container.read(playerControllerProvider).playing, isTrue);
      final mini = tester.getTopLeft(find.byType(PlayerView));
      expect(mini.dx, width >= 840 ? AppLayoutTokens.navigationRailWidth : 0);
      expect(tester.takeException(), isNull);
    }
    controller.open();
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expect(controller.isPanelOpen, isTrue);
    expect(tester.state(find.byType(PlayerView)), same(playerState));
    expect(tester.getTopLeft(find.byType(PlayerView)), Offset.zero);
    expect(tester.getSize(find.byType(PlayerView)).width, 1000);
    expect(container.read(playerControllerProvider).playing, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
    'phone rotation keeps bottom navigation, page state and search access',
    (tester) async {
      var created = 0;
      await _mount(
        tester,
        size: const Size(390, 844),
        platform: TargetPlatform.iOS,
        onCreated: () => created++,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(AdaptiveNavigationRail), findsNothing);
      await tester.tap(find.text('count 0'));
      await tester.drag(
        find.byKey(const Key('stateful-list')),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final offset = state.scroll.offset;
      tester.view.physicalSize = const Size(844, 390);
      tester.view.viewPadding = const FakeViewPadding(
        left: 47,
        right: 47,
        bottom: 21,
      );
      tester.view.padding = const FakeViewPadding(
        left: 47,
        right: 47,
        bottom: 21,
      );
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('count 1'), findsOneWidget);
      expect(state.scroll.offset, offset);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(AdaptiveNavigationRail), findsNothing);
      expect(find.byType(GlobalSearchInput), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('搜索作品'));
      await tester.pumpAndSettle();
      expect(find.text('Search destination'), findsOneWidget);
    },
  );

  testWidgets('desktop crosses 840 without recreating page or losing scroll', (
    tester,
  ) async {
    var created = 0;
    final router = await _mount(
      tester,
      size: const Size(839, 700),
      platform: TargetPlatform.macOS,
      onCreated: () => created++,
    );
    await tester.tap(find.text('count 0'));
    await tester.drag(
      find.byKey(const Key('stateful-list')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    final state = tester.state<_TestPageState>(find.byType(_TestPage));
    final offset = state.scroll.offset;
    for (final width in [840.0, 1440.0, 839.0, 840.0]) {
      tester.view.physicalSize = Size(width, 700);
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('count 1'), findsOneWidget);
      expect(state.scroll.offset, offset);
      expect(
        find.byType(NavigationBar),
        width < 840 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(AdaptiveNavigationRail),
        width >= 840 ? findsOneWidget : findsNothing,
      );
      expect(find.byType(GlobalSearchInput), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('分类'),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.category);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('首页'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget);
    expect(state.scroll.offset, offset);
    await tester.tap(find.byType(GlobalSearchInput));
    await tester.pumpAndSettle();
    expect(find.text('Search destination'), findsOneWidget);
  });

  testWidgets(
    'Windows window controls remain reachable in narrow and wide windows',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('window_manager');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await _mount(
        tester,
        size: const Size(390, 700),
        platform: TargetPlatform.windows,
        onCreated: () {},
      );
      for (final width in [390.0, 1000.0]) {
        tester.view.physicalSize = Size(width, 700);
        await tester.pumpAndSettle();
        for (final label in ['搜索', '全屏', '最小化', '最大化', '关闭']) {
          expect(find.byTooltip(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
