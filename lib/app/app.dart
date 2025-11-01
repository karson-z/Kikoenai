import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/user/presentation/view_models/user_view_model.dart';
import '../core/theme/theme_view_model.dart';
import '../core/widgets/side_shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (_, themeVM, __) => MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.light(themeVM.seedColor),
          darkTheme: AppTheme.dark(themeVM.seedColor),
          themeMode: themeVM.themeMode,
          home: const SideShell(),
          routes: {
            AppRoutes.settingsTheme: (_) => const SettingsPage(),
          },
        ),
      ),
    );
  }
}
