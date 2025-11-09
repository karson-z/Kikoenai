import 'package:flutter/material.dart';
import 'package:name_app/config/dependencies.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/theme_view_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<ThemeViewModel>(
        builder: (_, themeVM, __) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light(themeVM.seedColor),
          darkTheme: AppTheme.dark(themeVM.seedColor),
          themeMode: themeVM.themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}
