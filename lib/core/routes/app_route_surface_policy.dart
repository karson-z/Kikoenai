import 'package:kikoenai/features/album/widget/smart_works_sliver_grid.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../service/site/site_availability.dart';
import 'app_routes.dart';

/// Central mapping from routes to application surfaces.
class AppRouteSurfacePolicy {
  const AppRouteSurfacePolicy();

  AppSurface? surfaceFor(String path, {Object? extra}) {
    if (path == AppRoutes.settingsGlobalFilter) {
      return AppSurface.globalFilterPage;
    }
    return switch (path) {
      AppRoutes.home => AppSurface.homePage,
      AppRoutes.category => AppSurface.categoryPage,
      AppRoutes.search => AppSurface.searchPage,
      AppRoutes.login => AppSurface.authPage,
      AppRoutes.hotAndRecommend => _homeSectionSurface(extra),
      AppRoutes.detail => AppSurface.remoteAlbumDetailPage,
      _ => null,
    };
  }

  bool isAvailable({
    required String path,
    required SiteRuntime activeRuntime,
    required SurfacePolicyRegistry surfacePolicies,
    Object? extra,
  }) {
    final surface = surfaceFor(path, extra: extra);
    if (surface == null) return true;

    return surfacePolicies.isAvailable(surface, activeRuntime);
  }

  AppSurface _homeSectionSurface(Object? extra) {
    final source = _extraMap(extra)?['source'];
    return switch (source) {
      WorkDataSource.hot => AppSurface.homePopularSection,
      WorkDataSource.recommended => AppSurface.homeRecommendedSection,
      _ => AppSurface.homeNewestSection,
    };
  }

  Map<dynamic, dynamic>? _extraMap(Object? extra) {
    return extra is Map ? extra : null;
  }
}

const appRouteSurfacePolicy = AppRouteSurfacePolicy();
