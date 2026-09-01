import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/provider/video_brightness_provider.dart';
import 'package:kikoenai/features/player/widget/video/player_video_gesture_layer.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _FakeBrightnessService implements VideoBrightnessService {
  _FakeBrightnessService(this.currentBrightness);

  double currentBrightness;
  final List<double> setValues = [];
  int resetCount = 0;

  @override
  Future<double> get applicationBrightness async => currentBrightness;

  @override
  Future<void> setApplicationBrightness(double brightness) async {
    currentBrightness = brightness;
    setValues.add(brightness);
  }

  @override
  Future<void> resetApplicationBrightness() async {
    resetCount++;
  }
}

class _TestPlayerController extends PlayerController {
  @override
  AppPlayerState build() => const AppPlayerState(volume: 0.4);

  @override
  Future<void> setVolume(double value) async {
    state = state.copyWith(volume: value);
  }
}

void main() {
  testWidgets('video gestures adjust and restore application brightness', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final brightness = _FakeBrightnessService(0.4);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith(_TestPlayerController.new),
          videoBrightnessServiceProvider.overrideWithValue(brightness),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: VideoGestureLayer(child: ColoredBox(color: Colors.black)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final leftGesture = await tester.startGesture(const Offset(60, 300));
    await leftGesture.moveBy(const Offset(0, -40));
    await leftGesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await leftGesture.up();
    await tester.pump();

    expect(brightness.setValues, isNotEmpty);
    expect(brightness.setValues.last, greaterThan(0.4));
    final brightnessPercent = (brightness.setValues.last * 100).toInt();
    expect(find.text('亮度：$brightnessPercent%'), findsOneWidget);

    final setCount = brightness.setValues.length;
    final rightGesture = await tester.startGesture(const Offset(740, 300));
    await rightGesture.moveBy(const Offset(0, -40));
    await rightGesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await rightGesture.up();
    await tester.pump();

    expect(brightness.setValues, hasLength(setCount));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(VideoGestureLayer)),
    );
    expect(container.read(playerControllerProvider).volume, greaterThan(0.4));

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(brightness.resetCount, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
