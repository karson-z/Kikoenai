import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/lyrics/lyrics_parse_service.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/core/widgets/slider/player_sheet_panel.dart';
import 'package:kikoenai/features/player/page/player_view.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/player_lyrics_match_provider.dart';
import 'package:kikoenai/features/player/provider/player_lyrics_provider.dart';
import 'package:kikoenai/features/player/widget/audio/player_background.dart';
import 'package:kikoenai/features/player/widget/audio/player_controls.dart';
import 'package:kikoenai/features/player/widget/audio/player_info.dart';
import 'package:kikoenai/features/player/widget/lyrics/player_lyrics_panel.dart';
import 'package:kikoenai/features/player/widget/other/player_progress_bar.dart';
import 'package:kikoenai/features/player/widget/other/player_top_bar.dart';
import 'package:kikoenai/features/player/widget/player_layout.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

const _track = PlaybackItem(
  id: 'track',
  url: '/sample.mp3',
  title: 'Quiet evening',
  artist: 'Sample artist',
  scopeId: 'sample',
  source: NodeSource.localSingle,
);

class _TestPlayer extends PlayerController {
  @override
  AppPlayerState build() => const AppPlayerState(
    volume: 0.4,
    session: PlaybackSession(
      id: 'session',
      createdAt: 0,
      updatedAt: 0,
      queue: [_track],
    ),
    progressBarState: ProgressBarState(
      current: Duration(seconds: 30),
      buffered: Duration(minutes: 3),
      total: Duration(minutes: 5),
    ),
  );

  @override
  Future<void> seek(Duration position) async {
    state = state.copyWith(
      progressBarState: ProgressBarState(
        current: position,
        buffered: state.progressBarState.buffered,
        total: state.progressBarState.total,
      ),
    );
  }

  @override
  Future<void> setVolume(double value) async =>
      state = state.copyWith(volume: value);

  @override
  Future<void> play() async => state = state.copyWith(playing: true);

  @override
  Future<void> pause() async => state = state.copyWith(playing: false);

  void updateTrackTitle(String title) {
    state = state.copyWith(
      session: state.session!.copyWith(queue: [_track.copyWith(title: title)]),
    );
  }
}

class _TestLyrics extends LyricsMatchController {
  @override
  LyricsMatchState build() => LyricsMatchState(
    subtitleMapping: {
      'track': FileNode(
        type: NodeType.text,
        title: 'Sample',
        mediaStreamUrl: 'sample.lrc',
      ),
    },
  );
}

class _NoLyrics extends LyricsMatchController {
  @override
  LyricsMatchState build() => const LyricsMatchState();
}

final _cover = find.byKey(const ValueKey('player-shared-cover'));
const _captureKey = ValueKey('player-test-capture');

PageController _pageController(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!;

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  ValueNotifier<double>? expansion,
  PanelController? panel,
  bool noLyrics = false,
  double? contentWidth,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final expand = expansion ?? ValueNotifier(1.0);
  if (expansion == null) addTearDown(expand.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerControllerProvider.overrideWith(_TestPlayer.new),
        lyricsMatchControllerProvider.overrideWith(
          noLyrics ? _NoLyrics.new : _TestLyrics.new,
        ),
        blurredImageProvider.overrideWith((ref) async => null),
        lyricsContentProvider.overrideWith(
          (ref, url) async => List.generate(
            30,
            (i) =>
                '[${(i * 10 ~/ 60).toString().padLeft(2, '0')}:${(i * 10 % 60).toString().padLeft(2, '0')}.00]A quiet moment, line ${i + 1}',
          ).join('\n'),
        ),
        lyricStyleProvider.overrideWithValue(
          LyricStyleFactory.createStyle(const LyricConfigModel()),
        ),
        if (panel != null) panelControllerProvider.overrideWithValue(panel),
      ],
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'PlayerReview',
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: padding,
            viewPadding: padding,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: _captureKey,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: contentWidth,
                child: panel == null
                    ? PlayerView(dragProgressNotifier: expand, minHeight: 75)
                    : PlayerSheetPanel(
                        controller: panel,
                        minHeight: 75,
                        maxHeight: size.height,
                        defaultPanelState: PanelState.OPEN,
                        panelBuilder: (_, animation) => PlayerView(
                          dragProgressNotifier: animation,
                          minHeight: 75,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Optional local visual QA; normal test runs do not create files or load fonts.
Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['KIKO_PLAYER_REVIEW_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // text_scroll schedules an uncancellable initial Future.delayed(2s).
  // Drain it after disposal so it cannot leak into another widget test.
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUpAll(() async {
    if (Platform.environment['KIKO_PLAYER_REVIEW_DIR'] == null) return;
    final loader = FontLoader('PlayerReview');
    for (final path in [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/System/Library/Fonts/STHeiti Light.ttc',
    ]) {
      if (await File(path).exists()) {
        loader.addFont(
          File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      }
    }
    await loader.load();
    // Widget tests substitute Ahem for inherited canvas text and don't load
    // Material icons automatically. Use real fonts for the optional PNGs.
    for (final family in [
      'CupertinoSystemDisplay',
      'CupertinoSystemText',
      'sans-serif',
    ]) {
      final fallback = FontLoader(family)
        ..addFont(
          File(
            '/System/Library/Fonts/Supplemental/Arial.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await fallback.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await icons.load();
  });

  testWidgets(
    'cover tap does not switch; swiping moves pages and cover together',
    (tester) async {
      await _mount(tester);
      final albumRect = tester.getRect(_cover);
      final topBarRect = tester.getRect(find.byType(TopBar));
      final controller = _pageController(tester);
      await _capture(tester, 'phone-playback');

      await tester.tapAt(albumRect.center);
      await tester.pumpAndSettle();
      expect(controller.page, 0);

      final drag = await tester.startGesture(albumRect.center);
      await drag.moveBy(const Offset(-30, 0));
      await drag.moveBy(const Offset(-140, 0));
      await tester.pump();
      final page = controller.page!;
      final middleRect = tester.getRect(_cover);
      expect(page, inExclusiveRange(0, 1));
      expect(
        middleRect.width,
        closeTo(ui.lerpDouble(albumRect.width, 50, page)!, 0.01),
      );
      expect(tester.getRect(find.byType(TopBar)), topBarRect);
      await _capture(tester, 'phone-transition');
      await drag.moveBy(const Offset(-200, 0));
      await drag.up();
      await tester.pumpAndSettle();
      expect(controller.page, 1);
      expect(tester.getSize(_cover), const Size(50, 50));
      expect(tester.getRect(_cover).left, 24);
      await _capture(tester, 'phone-lyrics');

      await tester.tapAt(tester.getCenter(_cover));
      await tester.pumpAndSettle();
      expect(controller.page, 1);
      await tester.dragFrom(tester.getCenter(_cover), const Offset(340, 0));
      await tester.pumpAndSettle();
      expect(controller.page, 0);
      expect(tester.getRect(_cover), albumRect);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('partially reversing a swipe restores the starting cover', (
    tester,
  ) async {
    await _mount(tester);
    final albumRect = tester.getRect(_cover);
    final drag = await tester.startGesture(albumRect.center);
    await drag.moveBy(const Offset(-130, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await drag.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await drag.up();
    await tester.pumpAndSettle();
    expect(_pageController(tester).page, 0);
    expect(tester.getRect(_cover), albumRect);
    await _unmount(tester);
  });

  testWidgets('progress and volume drags keep the playback page selected', (
    tester,
  ) async {
    await _mount(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerView)),
    );
    final progress = tester.getRect(find.byType(PlayerProgressBar));
    await tester.dragFrom(
      Offset(progress.left + 70, progress.top + 6),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(_pageController(tester).page, 0);
    expect(
      container.read(playerControllerProvider).progressBarState.current,
      greaterThan(const Duration(seconds: 30)),
    );

    final slider = find.descendant(
      of: find.byType(PlayerVolumeSlider),
      matching: find.byType(Slider),
    );
    await tester.drag(slider, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(_pageController(tester).page, 0);
    expect(container.read(playerControllerProvider).volume, greaterThan(0.4));
    await _unmount(tester);
  });

  testWidgets(
    'breakpoint changes preserve the lyric controller and mobile page',
    (tester) async {
      await _mount(tester);
      await tester.dragFrom(tester.getCenter(_cover), const Offset(-340, 0));
      await tester.pumpAndSettle();
      final lyrics = tester.widget<LyricView>(find.byType(LyricView));

      tester.view.physicalSize = const Size(1100, 700);
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('player-split-view')), findsOneWidget);
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(lyrics.controller),
      );
      final lyricBounds = tester.getRect(find.byType(LyricsPanel));
      expect(tester.getRect(_cover).right, lessThan(lyricBounds.left));
      expect(
        tester.getRect(find.byType(PlayerControls)).right,
        lessThan(lyricBounds.left),
      );
      expect(find.byType(PlayerControls).hitTestable(), findsOneWidget);
      await _capture(tester, 'desktop-split');

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(_pageController(tester).page, 1);
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(lyrics.controller),
      );
      expect(tester.getSize(_cover), const Size(50, 50));
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets(
    'metadata updates preserve the selected page and subtitle state',
    (tester) async {
      await _mount(tester);
      await tester.dragFrom(tester.getCenter(_cover), const Offset(-340, 0));
      await tester.pumpAndSettle();
      final lyrics = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlayerView)),
      );
      (container.read(playerControllerProvider.notifier) as _TestPlayer)
          .updateTrackTitle('Updated track');
      await tester.pumpAndSettle();
      expect(_pageController(tester).page, 1);
      expect(find.text('Updated track').hitTestable(), findsOneWidget);
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(lyrics),
      );
      await _unmount(tester);
    },
  );

  testWidgets(
    'lyrics scrolling does not close the panel and reopening restores its page',
    (tester) async {
      final panel = PanelController();
      await _mount(tester, panel: panel);
      await tester.dragFrom(tester.getCenter(_cover), const Offset(-340, 0));
      await tester.pumpAndSettle();
      final lyrics = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      await tester.drag(find.byType(LyricView), const Offset(0, -160));
      await tester.pump(const Duration(milliseconds: 200));
      expect(panel.isPanelOpen, isTrue);
      expect(_pageController(tester).page, 1);
      expect(lyrics.isSelectingNotifier.value, isTrue);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(panel.isPanelClosed, isTrue);
      expect(tester.getSize(_cover), const Size(65, 65));
      await tester.tapAt(tester.getCenter(_cover));
      await tester.pumpAndSettle();
      expect(panel.isPanelOpen, isTrue);
      expect(_pageController(tester).page, 1);
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(lyrics),
      );
      await tester.dragFrom(tester.getCenter(_cover), const Offset(340, 0));
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getCenter(_cover), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(panel.isPanelClosed, isTrue);
      await _unmount(tester);
    },
  );

  testWidgets('no-subtitle page can still be swiped back', (tester) async {
    await _mount(tester, noLyrics: true);
    await tester.dragFrom(tester.getCenter(_cover), const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(find.text('暂无字幕').hitTestable(), findsOneWidget);
    await tester.dragFrom(const Offset(50, 430), const Offset(330, 0));
    await tester.pumpAndSettle();
    expect(_pageController(tester).page, 0);
    await _unmount(tester);
  });

  testWidgets(
    'resizing during a swipe restores a settled page and matching cover',
    (tester) async {
      await _mount(tester);
      final drag = await tester.startGesture(tester.getCenter(_cover));
      await drag.moveBy(const Offset(-30, 0));
      await drag.moveBy(const Offset(-210, 0));
      await tester.pump();
      expect(_pageController(tester).page, inExclusiveRange(0.5, 1));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      await drag.up();
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(_pageController(tester).page, 1);
      expect(tester.getSize(_cover), const Size(50, 50));
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets(
    'wide to narrow restores the playback page without recreating lyrics',
    (tester) async {
      await _mount(tester, size: const Size(1000, 700));
      final controller = tester
          .widget<LyricView>(find.byType(LyricView))
          .controller;
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(_pageController(tester).page, 0);
      expect(
        tester
            .widget<LyricView>(find.byType(LyricView, skipOffstage: false))
            .controller,
        same(controller),
      );
      expect(tester.getSize(_cover).width, greaterThan(50));
      await _unmount(tester);
    },
  );

  testWidgets(
    'window constraints choose the layout even inside a wider screen',
    (tester) async {
      // The host screen is wide while the player occupies a narrow pane.
      await _mount(tester, size: const Size(1200, 844), contentWidth: 390);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const ValueKey('player-split-view')), findsNothing);
      await _unmount(tester);
    },
  );

  test('layout policy accounts for shape, safe area and readable content', () {
    for (final scenario in [
      (size: const Size(390, 844), mode: PlayerLayoutMode.paged),
      (size: const Size(700, 1980), mode: PlayerLayoutMode.paged),
      (size: const Size(768, 1024), mode: PlayerLayoutMode.stacked),
      (size: const Size(1000, 1980), mode: PlayerLayoutMode.stacked),
      (size: const Size(1440, 1980), mode: PlayerLayoutMode.stacked),
      (size: const Size(1024, 768), mode: PlayerLayoutMode.sideBySide),
      (size: const Size(1920, 1080), mode: PlayerLayoutMode.sideBySide),
      (size: const Size(2560, 1980), mode: PlayerLayoutMode.sideBySide),
    ]) {
      final metrics = PlayerLayoutMetrics(
        size: scenario.size,
        padding: EdgeInsets.zero,
        textScaler: TextScaler.noScaling,
        minHeight: 75,
      );
      expect(metrics.mode, scenario.mode, reason: '${scenario.size}');
    }

    PlayerLayoutMetrics constrained({
      Size size = const Size(1000, 500),
      EdgeInsets padding = EdgeInsets.zero,
      double scale = 2,
    }) => PlayerLayoutMetrics(
      size: size,
      padding: padding,
      textScaler: TextScaler.linear(scale),
      minHeight: 75,
    );
    // Two columns no longer leave room for a cover with enlarged text.
    expect(constrained().mode, PlayerLayoutMode.paged);
    expect(
      constrained(
        size: const Size(820, 1200),
        padding: const EdgeInsets.symmetric(horizontal: 60),
        scale: 1,
      ).mode,
      PlayerLayoutMode.paged,
    );
    // Tall enough for stacking, but too narrow for readable large text.
    expect(
      constrained(size: const Size(720, 1980), scale: 3).mode,
      PlayerLayoutMode.paged,
    );
    expect(
      constrained(size: const Size(2560, 1980), scale: 2.9).mode,
      PlayerLayoutMode.paged,
    );
    expect(
      constrained(size: const Size(1000, 1980), scale: 3).mode,
      PlayerLayoutMode.paged,
    );
  });

  test('bounded playback regions stay centered with enlarged text', () {
    for (final width in [320.0, 390.0, 600.0]) {
      for (final height in [568.0, 844.0, 1980.0]) {
        for (final scale in [1.0, 2.0]) {
          final metrics = PlayerLayoutMetrics(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 20),
            textScaler: TextScaler.linear(scale),
            minHeight: 75,
          );
          final slots = [
            metrics.coverSlot,
            metrics.infoSlot,
            metrics.progressSlot,
            metrics.controlsSlot,
            metrics.volumeSlot,
          ];
          expect(
            slots.first.top + slots.last.bottom,
            closeTo(metrics.playbackViewport.height, 0.001),
          );
          for (var i = 1; i < slots.length; i++) {
            expect(slots[i].top, closeTo(slots[i - 1].bottom, 0.001));
          }
          expect(metrics.controlsSlot.height, inInclusiveRange(70, 88));
          expect(metrics.volumeSlot.height, inInclusiveRange(48, 64));
        }
      }
    }
  });

  testWidgets('all three modes preserve lyrics and the selected mobile page', (
    tester,
  ) async {
    await _mount(tester);
    await tester.dragFrom(tester.getCenter(_cover), const Offset(-340, 0));
    await tester.pumpAndSettle();
    final lyricController = tester
        .widget<LyricView>(find.byType(LyricView))
        .controller;
    await tester.drag(find.byType(LyricView), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 100));
    expect(lyricController.isSelectingNotifier.value, isTrue);

    for (final scenario in [
      (size: const Size(1000, 1980), key: 'player-stacked-view'),
      (size: const Size(1440, 900), key: 'player-split-view'),
      (size: const Size(768, 1024), key: 'player-stacked-view'),
      (size: const Size(390, 844), key: 'player-page-view'),
    ]) {
      tester.view.physicalSize = scenario.size;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(ValueKey(scenario.key)), findsOneWidget);
      expect(
        tester.widget<LyricView>(find.byType(LyricView)).controller,
        same(lyricController),
      );
      expect(lyricController.isSelectingNotifier.value, isTrue);
      if (scenario.key != 'player-page-view') {
        expect(find.byType(PageView), findsNothing);
        expect(
          find.byKey(const ValueKey('player-lyrics-header')),
          findsNothing,
        );
        expect(find.byType(PlayerControls).hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    expect(_pageController(tester).page, 1);
    expect(tester.getSize(_cover), const Size(50, 50));
    await _unmount(tester);
  });

  for (final scenario in [
    (name: 'portrait-tablet', size: const Size(768, 1024), scale: 1.0),
    (name: 'tall-desktop', size: const Size(1000, 1980), scale: 1.0),
    (name: 'wide-portrait', size: const Size(1440, 1980), scale: 1.0),
    (name: 'tall-large-text', size: const Size(1000, 1980), scale: 2.0),
    (name: 'tablet-large-text', size: const Size(768, 1024), scale: 2.0),
  ]) {
    testWidgets('compact playback and lyrics fit ${scenario.name}', (
      tester,
    ) async {
      await _mount(tester, size: scenario.size, scale: scenario.scale);
      expect(find.byKey(const ValueKey('player-stacked-view')), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      final cover = tester.getRect(_cover);
      final lyrics = tester.getRect(find.byType(LyricsPanel));
      expect(cover.width, closeTo(cover.height, 0.01));
      expect(cover.width, inInclusiveRange(180, 280));
      expect(lyrics.width, lessThanOrEqualTo(760));
      expect(lyrics.height, inInclusiveRange(360, 900));
      expect(cover.bottom, lessThan(lyrics.top));
      expect(lyrics.bottom, lessThanOrEqualTo(scenario.size.height - 34));

      var previousBottom = 0.0;
      for (final type in [
        PlayerInfoWidget,
        PlayerProgressBar,
        PlayerControls,
        PlayerVolumeSlider,
      ]) {
        final bounds = tester.getRect(find.byType(type));
        expect(bounds.left, greaterThan(cover.right));
        expect(bounds.right, lessThanOrEqualTo(scenario.size.width - 24));
        expect(bounds.top, greaterThanOrEqualTo(previousBottom));
        expect(bounds.bottom, lessThan(lyrics.top));
        previousBottom = bounds.bottom;
      }
      final play = find.descendant(
        of: find.byType(PlayerControls),
        matching: find.byTooltip('播放'),
      );
      expect(tester.getSize(play).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(play).height, greaterThanOrEqualTo(44));
      await _capture(tester, scenario.name);
      await tester.tap(play);
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlayerView)),
      );
      expect(container.read(playerControllerProvider).playing, isTrue);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }

  testWidgets('huge landscape keeps playback and reading regions bounded', (
    tester,
  ) async {
    await _mount(tester, size: const Size(2560, 1980));
    expect(find.byKey(const ValueKey('player-split-view')), findsOneWidget);
    final cover = tester.getRect(_cover);
    final lyrics = tester.getRect(find.byType(LyricsPanel));
    final info = tester.getRect(find.byType(PlayerInfoWidget));
    final controls = tester.getRect(find.byType(PlayerControls));
    final volume = tester.getRect(find.byType(PlayerVolumeSlider));
    expect(cover.width, lessThanOrEqualTo(350));
    expect(lyrics.size, const Size(760, 900));
    expect(controls.right, lessThan(lyrics.left));
    expect(info.top - cover.bottom, lessThan(100));
    expect(volume.bottom - cover.top, lessThan(800));
    await _capture(tester, 'huge-landscape');
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets(
    'tall narrow pages center bounded content and share cover anchors',
    (tester) async {
      await _mount(tester, size: const Size(600, 1980));
      expect(find.byType(PageView), findsOneWidget);
      final cover = tester.getRect(_cover);
      final volume = tester.getRect(find.byType(PlayerVolumeSlider));
      expect(cover.width, lessThanOrEqualTo(450));
      expect(volume.bottom - cover.top, lessThan(850));
      await _capture(tester, 'tall-narrow-playback');
      await tester.dragFrom(cover.center, const Offset(-520, 0));
      await tester.pumpAndSettle();
      final header = tester.getRect(
        find.byKey(const ValueKey('player-lyrics-header')),
      );
      expect(header.contains(tester.getCenter(_cover)), isTrue);
      expect(tester.getSize(_cover), const Size(50, 50));
      await _capture(tester, 'tall-narrow-lyrics');
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('stacked lyrics scroll independently and survive panel reopen', (
    tester,
  ) async {
    final panel = PanelController();
    await _mount(tester, size: const Size(1000, 1980), panel: panel);
    final controller = tester
        .widget<LyricView>(find.byType(LyricView))
        .controller;
    final albumRect = tester.getRect(_cover);
    await tester.drag(find.byType(LyricView), const Offset(0, -160));
    await tester.pump(const Duration(milliseconds: 200));
    expect(panel.isPanelOpen, isTrue);
    expect(controller.isSelectingNotifier.value, isTrue);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(panel.isPanelClosed, isTrue);
    expect(tester.getSize(_cover), const Size(65, 65));
    await tester.tapAt(tester.getCenter(_cover));
    await tester.pumpAndSettle();
    expect(panel.isPanelOpen, isTrue);
    expect(tester.getRect(_cover), albumRect);
    expect(
      tester.widget<LyricView>(find.byType(LyricView)).controller,
      same(controller),
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('stacked no-subtitle state keeps playback controls usable', (
    tester,
  ) async {
    await _mount(tester, size: const Size(1000, 1980), noLyrics: true);
    expect(find.byKey(const ValueKey('player-stacked-view')), findsOneWidget);
    expect(find.text('暂无字幕').hitTestable(), findsOneWidget);
    expect(find.byType(PlayerControls).hitTestable(), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerView)),
    );
    final slider = find.descendant(
      of: find.byType(PlayerVolumeSlider),
      matching: find.byType(Slider),
    );
    await tester.drag(slider, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(container.read(playerControllerProvider).volume, greaterThan(0.4));
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final scenario in [
    (
      name: 'small-phone',
      size: const Size(320, 568),
      scale: 1.0,
      padding: const EdgeInsets.only(top: 20),
    ),
    (
      name: 'small-phone-large-text',
      size: const Size(320, 568),
      scale: 2.0,
      padding: const EdgeInsets.only(top: 20),
    ),
    (
      name: 'phone-large-text',
      size: const Size(390, 844),
      scale: 2.0,
      padding: const EdgeInsets.only(top: 47, bottom: 34),
    ),
    (
      name: 'landscape-phone',
      size: const Size(844, 390),
      scale: 1.0,
      padding: const EdgeInsets.only(left: 47, right: 47, bottom: 21),
    ),
    (
      name: 'short-desktop',
      size: const Size(1000, 500),
      scale: 2.0,
      padding: EdgeInsets.zero,
    ),
  ]) {
    testWidgets('all playback controls fit ${scenario.name}', (tester) async {
      await _mount(
        tester,
        size: scenario.size,
        scale: scenario.scale,
        padding: scenario.padding,
      );
      final bottom = scenario.size.height - scenario.padding.bottom;
      var previousBottom = tester.getRect(_cover).bottom;
      for (final type in [
        PlayerInfoWidget,
        PlayerProgressBar,
        PlayerControls,
        PlayerVolumeSlider,
      ]) {
        final rect = tester.getRect(find.byType(type));
        expect(
          rect.top,
          greaterThanOrEqualTo(previousBottom - 0.01),
          reason: '$type overlaps preceding content',
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(bottom),
          reason: '$type outside safe area',
        );
        previousBottom = rect.bottom;
      }
      final play = find.descendant(
        of: find.byType(PlayerControls),
        matching: find.byTooltip('播放'),
      );
      expect(tester.getSize(play).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(play).width, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      await _capture(tester, scenario.name);
      if (find.byType(PageView).evaluate().isNotEmpty) {
        await tester.dragFrom(
          tester.getCenter(_cover),
          Offset(-scenario.size.width * 0.85, 0),
        );
        await tester.pumpAndSettle();
        final header = tester.getRect(
          find.byKey(const ValueKey('player-lyrics-header')),
        );
        expect(header.contains(tester.getRect(_cover).center), isTrue);
        expect(
          tester.getRect(find.byType(LyricsPanel)).bottom,
          lessThanOrEqualTo(bottom),
        );
        expect(tester.takeException(), isNull);
      }
      await _unmount(tester);
    });
  }
}
