import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

abstract interface class VideoBrightnessService {
  Future<double> get applicationBrightness;

  Future<void> setApplicationBrightness(double brightness);

  Future<void> resetApplicationBrightness();
}

class ScreenBrightnessVideoService implements VideoBrightnessService {
  const ScreenBrightnessVideoService();

  @override
  Future<double> get applicationBrightness =>
      ScreenBrightness.instance.application;

  @override
  Future<void> setApplicationBrightness(double brightness) =>
      ScreenBrightness.instance.setApplicationScreenBrightness(brightness);

  @override
  Future<void> resetApplicationBrightness() =>
      ScreenBrightness.instance.resetApplicationScreenBrightness();
}

final videoBrightnessServiceProvider = Provider<VideoBrightnessService>(
  (ref) => const ScreenBrightnessVideoService(),
);
