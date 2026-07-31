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
      AppRoutes.detail when !_isLocalDetail(extra) =>
        AppSurface.remoteAlbumDetailPage,
      _ => null,
    };
  }

  bool isAvailable({
    required String path,
    required SiteRuntime activeRuntime,
    required SiteRegistry siteRegistry,
    required SurfacePolicyRegistry surfacePolicies,
    Object? extra,
  }) {
    final surface = surfaceFor(path, extra: extra);
    if (surface == null) return true;

    final runtime = path == AppRoutes.detail
        ? siteRegistry.runtimeOf(_detailSiteId(extra))
        : activeRuntime;
    if (runtime == null) return false;
    return surfacePolicies.isAvailable(surface, runtime);
  }

  AppSurface _homeSectionSurface(Object? extra) {
    final source = _extraMap(extra)?['source'];
    return switch (source) {
      WorkDataSource.hot => AppSurface.homePopularSection,
      WorkDataSource.recommended => AppSurface.homeRecommendedSection,
      _ => AppSurface.homeNewestSection,
    };
  }

  bool _isLocalDetail(Object? extra) {
    return _extraMap(extra)?['isLocal'] as bool? ?? false;
  }

  String _detailSiteId(Object? extra) {
    final values = _extraMap(extra);
    final explicitSiteId = values?['siteId'] as String?;
    if (explicitSiteId != null && explicitSiteId.isNotEmpty) {
      return explicitSiteId;
    }

    final work = values?['work'];
    if (work is Work && work.siteId != null && work.siteId!.isNotEmpty) {
      return work.siteId!;
    }
    if (work is Map) {
      final workSiteId = work['siteId'] as String?;
      if (workSiteId != null && workSiteId.isNotEmpty) return workSiteId;
    }
    return SiteContentId.legacySiteId;
  }

  Map<dynamic, dynamic>? _extraMap(Object? extra) {
    return extra is Map ? extra : null;
  }
}

const appRouteSurfacePolicy = AppRouteSurfacePolicy();
