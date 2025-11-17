import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void setupDesktopWindow() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
  doWhenWindowReady(() {
    const initialSize = Size(1200, 800);
    appWindow.size = initialSize;
    appWindow.minSize = const Size(300, 600);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}