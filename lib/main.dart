import 'package:flutter/material.dart';
import 'package:name_app/core/utils/window/window_init_desktop.dart';
import 'app/app.dart';
import 'core/di/init_di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDesktopWindow();
  await initDi();
  runApp(const MyApp());
}
