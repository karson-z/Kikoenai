import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(DisplayUtils.debugResetOrientationMemory);

  test('remembers the orientations from before fullscreen only once', () {
    DisplayUtils.rememberOrientationsForFullscreen(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
    ]);
    DisplayUtils.rememberOrientationsForFullscreen(const [
      DeviceOrientation.landscapeRight,
    ]);

    expect(DisplayUtils.orientationsBeforeFullscreen, [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
    ]);
  });

  test('forgets the saved orientations after they are consumed', () {
    DisplayUtils.rememberOrientationsForFullscreen(
      DisplayUtils.preferredOrientationsBeforeLock,
    );

    final saved = DisplayUtils.orientationsBeforeFullscreen;
    DisplayUtils.debugResetOrientationMemory();

    expect(saved, DisplayUtils.preferredOrientationsBeforeLock);
    expect(DisplayUtils.orientationsBeforeFullscreen, isNull);
  });
}
