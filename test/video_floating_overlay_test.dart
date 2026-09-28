import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_presentation_controller.dart';
import 'package:kikoenai/features/player/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/widget/video/video_floating_overlay.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

// Give the test's square Ahem glyphs enough room for the unchanged time label.
const _screen = Size(430, 932);
const _ios = TargetPlatformVariant({TargetPlatform.iOS});

const _video = PlaybackItem(
  id: 'video',
  url: '/sample.mp4',
  title: 'Sample video',
  scopeId: 'sample',
  source: NodeSource.localSingle,
  isVideo: true,
);

class _TestPlayer extends PlayerController {
  @override
  AppPlayerState build() => const AppPlayerState(
    playing: true,
    videoWidth: 1920,
    videoHeight: 1080,
    session: PlaybackSession(
      id: 'session',
      createdAt: 0,
      updatedAt: 0,
      queue: [_video],
    ),
    progressBarState: ProgressBarState(
      current: Duration(seconds: 30),
      buffered: Duration(minutes: 3),
      total: Duration(minutes: 5),
    ),
  );

  @override
  Future<bool> loadScreenBrightness() async => false;

  @override
  void startControlsHideTimer() {}

  void setVideoDimensions(int width, int height, {int rotate = 0}) {
    state = state.copyWith(
      videoWidth: width,
      videoHeight: height,
      videoRotate: rotate,
    );
  }
}

// Only the native video texture is replaced. Controls, presentation, playback
// state and fullscreen commands use the production implementations.
class _TestVideoSurface extends StatefulWidget {
  const _TestVideoSurface();

  @override
  State<_TestVideoSurface> createState() => _TestVideoSurfaceState();
}

class _TestVideoSurfaceState extends State<_TestVideoSurface> {
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}

void _expectRectClose(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.01));
  expect(actual.top, closeTo(expected.top, 0.01));
  expect(actual.width, closeTo(expected.width, 0.01));
  expect(actual.height, closeTo(expected.height, 0.01));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late VideoPresentationController presentation;
  late List<bool> fullscreenCommands;
  Completer<void>? pendingPlatformExit;

  setUp(() {
    fullscreenCommands = [];
    pendingPlatformExit = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          if (call.method == 'setFullScreen') {
            final isFullScreen =
                (call.arguments as Map)['isFullScreen'] as bool;
            fullscreenCommands.add(isFullScreen);
            if (!isFullScreen) await pendingPlatformExit?.future;
          }
          return null;
        });
    container = ProviderContainer(
      overrides: [playerControllerProvider.overrideWith(_TestPlayer.new)],
    );
    presentation = VideoPresentationController(
      vsync: const TestVSync(),
      beforeCollapse: () async {
        if (container.read(mainScaffoldProvider).isFullScreen) {
          await container
              .read(playerControllerProvider.notifier)
              .toggleVideoFullScreen();
        }
      },
    );
  });

  tearDown(() {
    presentation.dispose();
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  Future<void> mount(
    WidgetTester tester, {
    bool fullscreen = true,
    bool expanded = true,
    Size size = _screen,
    EdgeInsets padding = EdgeInsets.zero,
    Size? contentSize,
    int videoWidth = 1920,
    int videoHeight = 1080,
    int videoRotate = 0,
    VoidCallback? onBackgroundTap,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    (container.read(playerControllerProvider.notifier) as _TestPlayer)
        .setVideoDimensions(videoWidth, videoHeight, rotate: videoRotate);
    container.read(mainScaffoldProvider.notifier).setFullScreen(fullscreen);
    presentation.reset(expanded: expanded);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, padding: padding),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: contentSize?.width,
                  height: contentSize?.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (onBackgroundTap != null)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onBackgroundTap,
                          ),
                        ),
                      VideoFloatingOverlay(
                        controller: presentation,
                        videoSurface: const _TestVideoSurface(),
                      ),
                    ],
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

  final surface = find.byType(_TestVideoSurface);
  final collapseButton = find.byIcon(Icons.keyboard_arrow_down_rounded);

  Future<void> reveal(WidgetTester tester, {Size size = _screen}) async {
    final visible = tester.getRect(surface).intersect(Offset.zero & size);
    await tester.tapAt(visible.center);
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isFalse);
    expect(presentation.progress, 0);
  }

  for (final side in [VideoFloatingDock.left, VideoFloatingDock.right]) {
    final left = side == VideoFloatingDock.left;
    final sign = left ? -1.0 : 1.0;

    testWidgets('small overflow restores the full window on $side', (
      tester,
    ) async {
      await mount(tester, fullscreen: false, expanded: false);
      if (left) {
        presentation.setFloatingOffset(
          Offset(12 - tester.getRect(surface).left, 0),
        );
        await tester.pump();
      }
      final start = tester.getRect(surface);
      final gesture = await tester.startGesture(start.center);
      await gesture.moveBy(Offset(sign * 26, -35));
      await tester.pump();
      final dragged = tester.getRect(surface);
      expect(left ? dragged.left < 0 : dragged.right > _screen.width, isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      final settled = tester.getRect(surface);
      expect(presentation.isFloatingHidden, isFalse);
      expect(presentation.dockedSide, side);
      expect(
        left ? settled.left : settled.right,
        closeTo(left ? 12 : _screen.width - 12, 0.01),
      );
      expect(settled.top, closeTo(dragged.top, 0.01));
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);

    testWidgets('outward fling hides but inward fling keeps $side visible', (
      tester,
    ) async {
      await mount(tester, fullscreen: false, expanded: false);
      final initial = tester.getRect(surface);
      final startLeft = left ? 122.0 : _screen.width - 122 - initial.width;
      presentation.setFloatingOffset(Offset(startLeft - initial.left, 0));
      await tester.pump();
      // Enough travel to recognize a pan/fling, but the endpoint is still
      // outside the edge zone. Only outward velocity should cause hiding.
      await tester.fling(surface, Offset(sign * 60, 0), 1000);
      await tester.pumpAndSettle();
      expect(presentation.isFloatingHidden, isTrue);
      expect(presentation.dockedSide, side);
      await reveal(tester);
      await tester.fling(surface, Offset(-sign * 60, 0), 1000);
      await tester.pumpAndSettle();
      expect(presentation.isFloatingHidden, isFalse);
      expect(presentation.dockedSide, side);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);

    testWidgets(
      'hidden $side stays reachable after resizing and has a 44px tap target',
      (tester) async {
        await mount(
          tester,
          fullscreen: false,
          expanded: false,
          videoWidth: 1080,
          videoHeight: 1920,
        );
        final playback = container.read(playerControllerProvider);
        final surfaceState = tester.state(surface);
        await tester.drag(surface, Offset(sign * 1500, -1500));
        await tester.pumpAndSettle();
        expect(presentation.isFloatingHidden, isTrue);
        for (final size in [
          const Size(932, 430),
          const Size(200, 360),
          _screen,
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          final rect = tester.getRect(surface);
          expect(
            rect.intersect(Offset.zero & size).width,
            closeTo(rect.width * 0.1, 0.01),
          );
          expect(rect.top, greaterThanOrEqualTo(12));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 12));
          expect(presentation.dockedSide, side);
        }
        final hiddenRect = tester.getRect(surface);
        final hitPoint = Offset(
          left ? 40 : _screen.width - 40,
          hiddenRect.center.dy,
        );
        expect(hiddenRect.contains(hitPoint), isFalse);
        await tester.tapAt(hitPoint);
        await tester.pumpAndSettle();
        expect(presentation.isFloatingHidden, isFalse);
        expect(presentation.progress, 0);
        final restored = tester.getRect(surface);
        expect(restored.left, greaterThanOrEqualTo(12));
        expect(restored.right, lessThanOrEqualTo(_screen.width - 12));
        await tester.tap(surface);
        await tester.pumpAndSettle();
        expect(presentation.progress, 1);
        await tester.tap(collapseButton);
        await tester.pumpAndSettle();
        _expectRectClose(tester.getRect(surface), restored);
        expect(tester.state(surface), same(surfaceState));
        expect(container.read(playerControllerProvider), playback);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: _ios,
    );

    testWidgets('dragging the hidden $side inward restores it', (tester) async {
      await mount(tester, fullscreen: false, expanded: false);
      await tester.drag(surface, Offset(sign * 1500, 0));
      await tester.pumpAndSettle();
      final rect = tester.getRect(surface);
      final gesture = await tester.startGesture(
        Offset(left ? 40 : _screen.width - 40, rect.center.dy),
      );
      await gesture.moveBy(Offset(-sign * 60, -40));
      await tester.pump();
      expect(presentation.isFloatingDragging, isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(presentation.isFloatingHidden, isFalse);
      expect(presentation.dockedSide, side);
      expect(tester.getRect(surface).top, closeTo(rect.top - 40, 0.01));
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);

    testWidgets(
      'cancelled drag from the hidden $side tap extension restores it',
      (tester) async {
        await mount(
          tester,
          fullscreen: false,
          expanded: false,
          videoWidth: 1080,
          videoHeight: 1920,
        );
        await tester.drag(surface, Offset(sign * 1500, 0));
        await tester.pumpAndSettle();
        final rect = tester.getRect(surface);
        final start = Offset(left ? 40 : _screen.width - 40, rect.center.dy);
        expect(rect.contains(start), isFalse);
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(Offset(sign * 60, -40));
        await tester.pump();
        expect(presentation.isFloatingDragging, isTrue);
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(presentation.isFloatingHidden, isFalse);
        expect(presentation.dockedSide, side);
        final restored = tester.getRect(surface);
        expect(restored.left, greaterThanOrEqualTo(12));
        expect(restored.right, lessThanOrEqualTo(_screen.width - 12));
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: _ios,
    );
  }

  testWidgets(
    'slow outward travel near an edge hides without needing overflow',
    (tester) async {
      await mount(
        tester,
        fullscreen: false,
        expanded: false,
        videoWidth: 1080,
        videoHeight: 1920,
      );
      presentation.setFloatingOffset(const Offset(-60, 0));
      await tester.pump();
      final gesture = await tester.startGesture(tester.getCenter(surface));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(tester.getRect(surface).right, lessThan(_screen.width));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(presentation.isFloatingHidden, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: _ios,
  );

  testWidgets('vertical fling and ordinary inward drag stay fully visible', (
    tester,
  ) async {
    await mount(tester, fullscreen: false, expanded: false);
    await tester.fling(surface, const Offset(0, -250), 2000);
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isFalse);
    expect(tester.getRect(surface).right, closeTo(_screen.width - 12, 0.01));
    await tester.drag(surface, const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isFalse);
    expect(tester.getRect(surface).right, closeTo(_screen.width - 12, 0.01));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('cancelled outward drag restores the full window', (
    tester,
  ) async {
    await mount(tester, fullscreen: false, expanded: false);
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(100, -30));
    await tester.pump();
    expect(tester.getRect(surface).right, greaterThan(_screen.width));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isFalse);
    expect(tester.getRect(surface).right, closeTo(_screen.width - 12, 0.01));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('a new drag can interrupt docking without a jump', (
    tester,
  ) async {
    await mount(tester, fullscreen: false, expanded: false);
    await tester.drag(surface, const Offset(80, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final before = tester.getRect(surface);
    final gesture = await tester.startGesture(
      before.intersect(Offset.zero & _screen).center,
    );
    await gesture.moveBy(const Offset(-30, -20));
    await tester.pump();
    final after = tester.getRect(surface);
    expect(after.left, closeTo(before.left - 30, 0.01));
    expect(after.top, closeTo(before.top - 20, 0.01));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('media reset cancels docking and an active drag', (tester) async {
    await mount(tester, fullscreen: false, expanded: false);
    final initial = tester.getRect(surface);
    await tester.drag(surface, const Offset(80, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    presentation.reset(expanded: false);
    await tester.pumpAndSettle();
    _expectRectClose(tester.getRect(surface), initial);
    expect(presentation.isFloatingHidden, isFalse);
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(-100, -100));
    await tester.pump();
    presentation.reset(expanded: false);
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    _expectRectClose(tester.getRect(surface), initial);
    expect(presentation.isFloatingSettling, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('hidden hit area leaves the rest of the content interactive', (
    tester,
  ) async {
    var taps = 0;
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      onBackgroundTap: () => taps++,
    );
    await tester.drag(surface, const Offset(1500, 0));
    await tester.pumpAndSettle();
    final y = tester.getRect(surface).center.dy;
    await tester.tapAt(Offset(_screen.width - 60, y));
    expect(taps, 1);
    expect(presentation.isFloatingHidden, isTrue);
    await tester.tapAt(Offset(_screen.width - 40, y));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(presentation.isFloatingHidden, isFalse);
    expect(presentation.progress, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  for (final hidden in [false, true]) {
    testWidgets('edge animation applies one curve (hidden: $hidden)', (
      tester,
    ) async {
      await mount(tester, fullscreen: false, expanded: false);
      final gesture = await tester.startGesture(tester.getCenter(surface));
      await gesture.moveBy(Offset(hidden ? 80 : -60, -50));
      await tester.pump();
      final start = tester.getRect(surface);
      await gesture.up();
      await tester.pump();
      await tester.pump(Duration(milliseconds: hidden ? 90 : 110));
      final curve = hidden ? Curves.fastOutSlowIn : Curves.easeOutCubic;
      final left = hidden
          ? _screen.width - start.width * 0.1
          : _screen.width - 12 - start.width;
      final target = Rect.fromLTWH(left, start.top, start.width, start.height);
      _expectRectClose(
        tester.getRect(surface),
        Rect.lerp(start, target, curve.transform(0.5))!,
      );
      expect(presentation.progress, 0);
      await tester.pumpAndSettle();
      _expectRectClose(tester.getRect(surface), target);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);
  }

  for (final trigger in ['button', 'top-bar swipe']) {
    testWidgets('fullscreen $trigger returns to the same floating video', (
      tester,
    ) async {
      await mount(tester);
      final playback = container.read(playerControllerProvider);
      final surfaceState = tester.state(surface);
      expect(tester.getSize(surface), _screen);

      if (trigger == 'button') {
        await tester.tap(collapseButton);
      } else {
        await tester.fling(find.byType(VideoTopBar), const Offset(0, 120), 800);
      }
      await tester.pumpAndSettle();

      expect(container.read(mainScaffoldProvider).isFullScreen, isFalse);
      expect(fullscreenCommands, [false]);
      expect(presentation.progress, 0);
      expect(tester.getSize(surface).width, lessThan(_screen.width));
      expect(tester.getSize(surface).height, lessThan(_screen.height));
      expect(tester.state(surface), same(surfaceState));
      expect(container.read(playerControllerProvider), playback);

      // Expanding the floating video must not re-enter platform fullscreen.
      await tester.tap(surface);
      await tester.pumpAndSettle();
      expect(presentation.progress, 1);
      expect(tester.getSize(surface), _screen);
      expect(container.read(mainScaffoldProvider).isFullScreen, isFalse);
      expect(fullscreenCommands, [false]);
      expect(tester.state(surface), same(surfaceState));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);
  }

  testWidgets('normal expanded video collapses without toggling fullscreen', (
    tester,
  ) async {
    await mount(tester, fullscreen: false);
    await tester.tap(collapseButton);
    await tester.pumpAndSettle();
    expect(presentation.progress, 0);
    expect(container.read(mainScaffoldProvider).isFullScreen, isFalse);
    expect(fullscreenCommands, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('repeated collapse waits for one fullscreen exit', (
    tester,
  ) async {
    await mount(tester);
    pendingPlatformExit = Completer<void>();
    await tester.tap(collapseButton);
    await tester.pump();
    await tester.tap(collapseButton);
    await tester.pump(const Duration(milliseconds: 400));
    expect(presentation.progress, 1);
    expect(fullscreenCommands, [false]);

    pendingPlatformExit!.complete();
    await tester.pumpAndSettle();
    expect(presentation.progress, 0);
    expect(container.read(mainScaffoldProvider).isFullScreen, isFalse);
    expect(fullscreenCommands, [false]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('media reset cancels collapse while fullscreen exit is pending', (
    tester,
  ) async {
    await mount(tester);
    pendingPlatformExit = Completer<void>();
    await tester.tap(collapseButton);
    await tester.pump();
    presentation.reset(expanded: true);
    pendingPlatformExit!.complete();
    await tester.pumpAndSettle();
    expect(presentation.progress, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  for (final scenario in [
    (
      name: 'portrait phone',
      size: _screen,
      padding: const EdgeInsets.only(top: 47, bottom: 34),
    ),
    (
      name: 'landscape phone',
      size: const Size(932, 430),
      padding: const EdgeInsets.only(left: 47, right: 47, bottom: 21),
    ),
    (
      name: 'tablet',
      size: const Size(1024, 768),
      padding: const EdgeInsets.only(top: 24, bottom: 20),
    ),
  ]) {
    testWidgets('floating video reaches every corner on ${scenario.name}', (
      tester,
    ) async {
      await mount(
        tester,
        fullscreen: false,
        expanded: false,
        size: scenario.size,
        padding: scenario.padding,
      );
      final playback = container.read(playerControllerProvider);
      final surfaceState = tester.state(surface);
      final videoSize = tester.getSize(surface);
      final left = scenario.padding.left + 12;
      final top = scenario.padding.top + 12;
      final right = scenario.size.width - scenario.padding.right - 12;
      final bottom = scenario.size.height - scenario.padding.bottom - 12;

      // Pump between small pointer updates: the original bug changes the
      // clamp bounds on every rebuild, unlike a single large drag update.
      Future<void> drag(Offset delta) async {
        final gesture = await tester.startGesture(tester.getCenter(surface));
        await gesture.moveBy(delta / delta.distance * 30);
        await tester.pump(const Duration(milliseconds: 16));
        for (var step = 0; step < 60; step++) {
          await gesture.moveBy(delta / 60);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await drag(Offset(-scenario.size.width, -scenario.size.height));
      expect(presentation.isFloatingHidden, isTrue);
      expect(
        tester.getRect(surface).right,
        closeTo(videoSize.width * 0.1, 0.01),
      );
      await reveal(tester, size: scenario.size);
      expect(tester.getTopLeft(surface).dx, closeTo(left, 0.01));
      expect(tester.getTopLeft(surface).dy, closeTo(top, 0.01));
      await drag(Offset(scenario.size.width, 0));
      expect(presentation.isFloatingHidden, isTrue);
      expect(
        tester.getRect(surface).left,
        closeTo(scenario.size.width - videoSize.width * 0.1, 0.01),
      );
      await reveal(tester, size: scenario.size);
      expect(tester.getBottomRight(surface).dx, closeTo(right, 0.01));
      expect(tester.getTopLeft(surface).dy, closeTo(top, 0.01));
      await drag(Offset(0, scenario.size.height));
      expect(tester.getBottomRight(surface).dx, closeTo(right, 0.01));
      expect(tester.getBottomRight(surface).dy, closeTo(bottom, 0.01));
      await drag(Offset(-scenario.size.width, 0));
      await reveal(tester, size: scenario.size);
      expect(tester.getTopLeft(surface).dx, closeTo(left, 0.01));
      expect(tester.getBottomRight(surface).dy, closeTo(bottom, 0.01));

      // There must be no accumulated overscroll or jump when reversing at
      // an edge, even while the same pointer remains down.
      final gesture = await tester.startGesture(tester.getCenter(surface));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-1000, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final atEdge = tester.getTopLeft(surface);
      await gesture.moveBy(const Offset(40, -40));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(surface).dx, closeTo(atEdge.dx + 40, 0.01));
      expect(tester.getTopLeft(surface).dy, closeTo(atEdge.dy - 40, 0.01));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(presentation.isFloatingHidden, isFalse);

      final floatingRect = tester.getRect(surface);
      await tester.tap(surface);
      await tester.pumpAndSettle();
      await tester.tap(collapseButton);
      await tester.pumpAndSettle();
      expect(tester.getRect(surface), floatingRect);
      expect(tester.getSize(surface).width, closeTo(videoSize.width, 0.01));
      expect(tester.getSize(surface).height, closeTo(videoSize.height, 0.01));
      expect(tester.state(surface), same(surfaceState));
      expect(container.read(playerControllerProvider), playback);
      expect(fullscreenCommands, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);
  }

  testWidgets('floating video docks at its actual content edge', (
    tester,
  ) async {
    const contentSize = Size(640, 480);
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      size: const Size(1024, 768),
      contentSize: contentSize,
    );
    expect(tester.getBottomRight(surface).dx, lessThan(contentSize.width));
    expect(tester.getBottomRight(surface).dy, lessThan(contentSize.height));
    await tester.drag(surface, const Offset(500, 500));
    await tester.pumpAndSettle();
    expect(presentation.isFloatingHidden, isTrue);
    expect(
      tester.getRect(surface).left,
      closeTo(contentSize.width - tester.getSize(surface).width * 0.1, 0.01),
    );
    await reveal(tester, size: contentSize);
    expect(tester.getBottomRight(surface).dx, closeTo(628, 0.01));
    expect(tester.getBottomRight(surface).dy, closeTo(468, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('resizing keeps video reachable and the next drag follows it', (
    tester,
  ) async {
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      size: const Size(1024, 768),
    );
    final surfaceState = tester.state(surface);
    await tester.drag(surface, const Offset(-1100, -800));
    await tester.pumpAndSettle();
    await reveal(tester, size: const Size(1024, 768));

    for (final size in [const Size(932, 430), const Size(200, 360), _screen]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final rect = tester.getRect(surface);
      expect(rect.left, greaterThanOrEqualTo(12));
      expect(rect.top, greaterThanOrEqualTo(12));
      expect(rect.right, lessThanOrEqualTo(size.width - 12));
      expect(rect.bottom, lessThanOrEqualTo(size.height - 12));
      expect(tester.state(surface), same(surfaceState));
    }

    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final start = tester.getTopLeft(surface);
    await gesture.moveBy(const Offset(40, 40));
    await tester.pump(const Duration(milliseconds: 16));
    final end = tester.getTopLeft(surface);
    expect(end.dx, closeTo(start.dx + 40, 0.01));
    expect(end.dy, closeTo(start.dy + 40, 0.01));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  for (final video in [
    (name: '9:16 portrait', width: 1080, height: 1920, rotate: 0),
    (name: 'rotated 9:16 portrait', width: 1920, height: 1080, rotate: 90),
    (name: '3:4 portrait', width: 1080, height: 1440, rotate: 0),
    (name: '16:9 landscape', width: 1920, height: 1080, rotate: 0),
  ]) {
    testWidgets('${video.name} floating window uses its orientation frame', (
      tester,
    ) async {
      await mount(
        tester,
        fullscreen: false,
        expanded: false,
        size: const Size(390, 844),
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        videoWidth: video.width,
        videoHeight: video.height,
        videoRotate: video.rotate,
      );
      final window = tester.getRect(surface);
      final isPortrait = video.width < video.height || video.rotate == 90;
      final expectedRatio = isPortrait ? 9 / 16 : 16 / 9;
      expect(window.width / window.height, closeTo(expectedRatio, 0.001));
      if (isPortrait) {
        expect(window.height, closeTo(390 * 0.58, 0.01));
        expect(window.width, closeTo(390 * 0.58 * 9 / 16, 0.01));
      } else {
        expect(window.width, closeTo(390 * 0.58, 0.01));
      }
      expect(window.left, greaterThanOrEqualTo(12));
      expect(window.top, greaterThanOrEqualTo(47 + 12));
      expect(window.right, lessThanOrEqualTo(390 - 12));
      expect(window.bottom, lessThanOrEqualTo(844 - 34 - 12));
      if (isPortrait) {
        final surfaceState = tester.state(surface);
        await tester.drag(surface, const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        expect(presentation.isFloatingHidden, isTrue);
        await reveal(tester, size: const Size(390, 844));
        final movedWindow = tester.getRect(surface);
        expect(movedWindow.left, closeTo(12, 0.01));
        expect(movedWindow.top, closeTo(47 + 12, 0.01));
        await tester.tap(surface);
        await tester.pumpAndSettle();
        await tester.tap(collapseButton);
        await tester.pumpAndSettle();
        _expectRectClose(tester.getRect(surface), movedWindow);
        expect(tester.state(surface), same(surfaceState));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: _ios);
  }

  testWidgets('portrait frame scales uniformly inside a narrow content area', (
    tester,
  ) async {
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      size: const Size(390, 844),
      contentSize: const Size(170, 390),
      videoWidth: 1080,
      videoHeight: 1920,
    );
    final window = tester.getRect(surface);
    expect(window.width / window.height, closeTo(9 / 16, 0.001));
    expect(window.right, lessThanOrEqualTo(170 - 12));
    expect(window.bottom, lessThanOrEqualTo(390 - 12));
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('tall screens use the rotated landscape window size', (
    tester,
  ) async {
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      size: const Size(1024, 2048),
      videoWidth: 1080,
      videoHeight: 1920,
    );
    final window = tester.getRect(surface);
    expect(window.height, closeTo(360, 0.01));
    expect(window.width / window.height, closeTo(9 / 16, 0.001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets('small phone keeps every expanded video control visible', (
    tester,
  ) async {
    await mount(
      tester,
      fullscreen: false,
      expanded: false,
      size: const Size(320, 568),
      videoWidth: 1080,
      videoHeight: 1920,
    );
    await tester.tap(surface);
    await tester.pumpAndSettle();

    for (final icon in [
      Icons.skip_previous_rounded,
      Icons.pause_rounded,
      Icons.skip_next_rounded,
      Icons.format_list_bulleted_rounded,
      Icons.fullscreen_rounded,
    ]) {
      final rect = tester.getRect(find.byIcon(icon));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.bottom, lessThanOrEqualTo(568));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: _ios);

  testWidgets(
    'window position follows one curve with distinct collapse timing',
    (tester) async {
      await mount(tester, fullscreen: false, expanded: false);
      final floatingRect = tester.getRect(surface);

      presentation.expand();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      final expandProgress = Curves.easeOutCubic.transform(0.5);
      expect(presentation.progress, closeTo(expandProgress, 0.01));
      final expandedHalfway = tester.getRect(surface);
      final expectedExpanded = Rect.lerp(
        floatingRect,
        Offset.zero & _screen,
        presentation.progress,
      )!;
      _expectRectClose(expandedHalfway, expectedExpanded);
      await tester.pumpAndSettle();

      await tester.tap(collapseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final collapseProgress = 1 - Curves.fastOutSlowIn.transform(0.5);
      expect(presentation.progress, closeTo(collapseProgress, 0.01));
      final collapsedHalfway = tester.getRect(surface);
      final expectedCollapsed = Rect.lerp(
        floatingRect,
        Offset.zero & _screen,
        presentation.progress,
      )!;
      _expectRectClose(collapsedHalfway, expectedCollapsed);
      await tester.pumpAndSettle();
      expect(tester.getRect(surface), floatingRect);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: _ios,
  );
}
