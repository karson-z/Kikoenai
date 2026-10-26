import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// Coordinates phone rotation with the video's existing fullscreen mode.
class MobileSystemUiController {
  bool _phoneLandscape = false;
  bool _fullscreen = false;

  Future<void> setPhoneLandscape(bool landscape) async {
    _phoneLandscape = landscape;
    await _apply();
  }

  Future<void> enterFullscreen() async {
    _fullscreen = true;
    await _apply();
  }

  Future<void> exitFullscreen() async {
    _fullscreen = false;
    await _apply();
  }

  Future<void> _apply() async {
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (_phoneLandscape) {
      // Hide only the status bar; keep the home indicator/system navigation.
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [SystemUiOverlay.bottom],
      );
    } else {
      var mode = SystemUiMode.edgeToEdge;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 29) mode = SystemUiMode.manual;
        // Rotation or fullscreen may have changed while querying the device.
        if (_fullscreen || _phoneLandscape) return _apply();
      }
      await SystemChrome.setEnabledSystemUIMode(
        mode,
        overlays: SystemUiOverlay.values,
      );
    }
  }
}
