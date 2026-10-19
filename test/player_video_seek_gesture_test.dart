import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_brightness_provider.dart';
import 'package:kikoenai/features/player/provider/video_seek_preview_provider.dart';
import 'package:kikoenai/features/player/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/widget/video/player_video_gesture_layer.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _FakeBrightnessService implements VideoBrightnessService {
  @override
  Future<double> get applicationBrightness async => 0.4;

  @override
  Future<void> setApplicationBrightness(double brightness) async {}

  @override
  Future<void> resetApplicationBrightness() async {}
}

class _SeekTestPlayerController extends PlayerController {
  final List<Duration> seeks = [];

  @override
  AppPlayerState build() {
    ref.onDispose(() {});
    return const AppPlayerState(
      isVideoControlsVisible: false,
      progressBarState: ProgressBarState(
        current: Duration(seconds: 60),
        buffered: Duration(seconds: 90),
        total: Duration(seconds: 200),
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    state = state.copyWith(
      progressBarState: ProgressBarState(
        current: position,
        buffered: state.progressBarState.buffered,
        total: state.progressBarState.total,
      ),
    );
  }
}

void main() {
  testWidgets('horizontal seek drag raises controls and moves the bar', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    late _SeekTestPlayerController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith(() {
            controller = _SeekTestPlayerController();
            return controller;
          }),
          videoBrightnessServiceProvider.overrideWithValue(
            _FakeBrightnessService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoGestureLayer(child: SizedBox.expand()),
                  PlayerVideoControlsOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VideoGestureLayer)),
    );
    expect(
      container.read(playerControllerProvider).isVideoControlsVisible,
      isFalse,
    );

    // Full width maps to the whole 200s duration. 200px is +50s.
    final gesture = await tester.startGesture(const Offset(100, 300));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(
      container.read(playerControllerProvider).isVideoControlsVisible,
      isTrue,
    );
    expect(
      container.read(videoSeekPreviewProvider),
      const Duration(seconds: 70),
    );
    expect(find.text('1:10'), findsWidgets);
    expect(find.textContaining('1:10 /'), findsOneWidget);
    expect(controller.seeks, isEmpty);

    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();
    expect(
      container.read(videoSeekPreviewProvider),
      const Duration(seconds: 110),
    );
    expect(find.textContaining('1:50 /'), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(container.read(videoSeekPreviewProvider), isNull);
    expect(controller.seeks, [const Duration(seconds: 110)]);
    expect(
      container.read(playerControllerProvider).isVideoControlsVisible,
      isTrue,
    );
    expect(
      container.read(playerControllerProvider).progressBarState.current,
      const Duration(seconds: 110),
    );

    await tester.pump(kDoubleTapTimeout);
    await tester.pump(const Duration(seconds: 4));
    expect(
      container.read(playerControllerProvider).isVideoControlsVisible,
      isFalse,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a cancelled seek drag still seeks and keeps controls up', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    late _SeekTestPlayerController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith(() {
            controller = _SeekTestPlayerController();
            return controller;
          }),
          videoBrightnessServiceProvider.overrideWithValue(
            _FakeBrightnessService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: VideoGestureLayer(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VideoGestureLayer)),
    );
    final gesture = await tester.startGesture(const Offset(100, 300));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(container.read(videoSeekPreviewProvider), isNull);
    expect(controller.seeks, [const Duration(seconds: 80)]);
    expect(
      container.read(playerControllerProvider).isVideoControlsVisible,
      isTrue,
    );

    await tester.pump(kDoubleTapTimeout);
    await tester.pump(const Duration(seconds: 4));
    debugDefaultTargetPlatformOverride = null;
  });
}
