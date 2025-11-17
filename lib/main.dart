import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/utils/window/window_init_desktop.dart';
import 'app/app.dart';
import 'core/common/shared_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  setupDesktopWindow();
  runApp(const ProviderScope(child: MyApp()));
}
