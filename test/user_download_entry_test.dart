import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/features/auth/provider/auth_provider.dart';
import 'package:kikoenai/features/auth/provider/auth_state.dart';
import 'package:kikoenai/features/history/provider/history_controller_provider.dart';
import 'package:kikoenai/features/user/page/user_page.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(currentUser: null, token: null);
}

class _TestActiveSiteIdNotifier extends ActiveSiteIdNotifier {
  @override
  String build() => 'test-site';
}

class _TestHistoryController extends HistoryController {
  @override
  List<HistoryEntry> build() => const [];
}

void main() {
  testWidgets('opens downloads from the user page action instead of a tab', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.user,
      routes: [
        GoRoute(path: AppRoutes.user, builder: (_, __) => const UserPage()),
        GoRoute(
          path: AppRoutes.downloads,
          builder: (_, __) => const Scaffold(body: Text('download-route')),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const Scaffold(body: Text('settings-route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
          activeSiteIdProvider.overrideWith(_TestActiveSiteIdNotifier.new),
          availableSurfacesProvider.overrideWithValue(const {}),
          historyControllerProvider.overrideWith(_TestHistoryController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('下载列表'), findsNothing);
    expect(find.byTooltip('下载管理'), findsOneWidget);
    expect(find.byTooltip('设置'), findsOneWidget);

    await tester.tap(find.byTooltip('下载管理'));
    await tester.pumpAndSettle();

    expect(find.text('download-route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
