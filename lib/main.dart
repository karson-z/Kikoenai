import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/init_di.dart';

import 'core/utils/window_init_stub.dart'
    if (dart.library.io) 'core/utils/window_init_desktop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDesktopWindow();
  await initDi();
  runApp(const MyApp());
}