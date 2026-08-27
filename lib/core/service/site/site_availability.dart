import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import 'site_api_provider.dart';

/// Application surfaces whose availability can vary by site.
enum AppSurface {
  homePage,
  categoryPage,
  localMediaPage,
  cloudDrivePage,
  parsedWorksPage,
  userPage,
  settingsPage,
  homePopularSection,
  homeRecommendedSection,
  homeNewestSection,
  searchPage,
  remoteAlbumDetailPage,
  albumTracksSection,
  albumSimilarWorks,
  authPage,
  loginAction,
  registerAction,
  userReviewsTab,
  userPlaylistsTab,
  submitReviewAction,
  addToPlaylistAction,
  defaultPlaylistSetting,
  serverSelector,
  globalFilterPage,
}

class SiteAvailabilityContext {
  const SiteAvailabilityContext(this.runtime);

  final SiteRuntime runtime;
}

sealed class SiteRequirement {
  const SiteRequirement();

  bool isSatisfiedBy(SiteAvailabilityContext context);
}

class Always extends SiteRequirement {
  const Always();

  @override
  bool isSatisfiedBy(SiteAvailabilityContext context) => true;
}

class Supports extends SiteRequirement {
  const Supports(this.feature);

  final SiteFeature feature;

  @override
  bool isSatisfiedBy(SiteAvailabilityContext context) {
    return context.runtime.api.supports(feature);
  }
}

class AnyOf extends SiteRequirement {
  const AnyOf(this.requirements);

  final List<SiteRequirement> requirements;

  @override
  bool isSatisfiedBy(SiteAvailabilityContext context) {
    return requirements.any(
      (requirement) => requirement.isSatisfiedBy(context),
    );
  }
}

class AllOf extends SiteRequirement {
  const AllOf(this.requirements);

  final List<SiteRequirement> requirements;

  @override
  bool isSatisfiedBy(SiteAvailabilityContext context) {
    return requirements.every(
      (requirement) => requirement.isSatisfiedBy(context),
    );
  }
}

class HasServers extends SiteRequirement {
  const HasServers();

  @override
  bool isSatisfiedBy(SiteAvailabilityContext context) {
    return context.runtime.info.servers.isNotEmpty;
  }
}

class SurfacePolicyRegistry {
  const SurfacePolicyRegistry(this._policies);

  final Map<AppSurface, SiteRequirement> _policies;

  bool isAvailable(AppSurface surface, SiteRuntime runtime) {
    final requirement = _policies[surface];
    if (requirement == null) return false;
    return requirement.isSatisfiedBy(SiteAvailabilityContext(runtime));
  }

  Set<AppSurface> availableFor(SiteRuntime runtime) {
    return Set.unmodifiable(
      AppSurface.values.where((surface) => isAvailable(surface, runtime)),
    );
  }
}

const defaultSurfacePolicyRegistry = SurfacePolicyRegistry({
  AppSurface.homePage: AnyOf([
    Supports(SiteFeature.popular),
    Supports(SiteFeature.recommend),
    Supports(SiteFeature.search),
  ]),
  AppSurface.categoryPage: Supports(SiteFeature.search),
  AppSurface.localMediaPage: Always(),
  AppSurface.cloudDrivePage: Always(),
  AppSurface.parsedWorksPage: Always(),
  AppSurface.userPage: Always(),
  AppSurface.settingsPage: Always(),
  AppSurface.homePopularSection: Supports(SiteFeature.popular),
  AppSurface.homeRecommendedSection: Supports(SiteFeature.recommend),
  AppSurface.homeNewestSection: Supports(SiteFeature.search),
  AppSurface.searchPage: Supports(SiteFeature.search),
  AppSurface.remoteAlbumDetailPage: AllOf([
    Supports(SiteFeature.detail),
    Supports(SiteFeature.tracks),
  ]),
  AppSurface.albumTracksSection: Supports(SiteFeature.tracks),
  AppSurface.albumSimilarWorks: Supports(SiteFeature.search),
  AppSurface.authPage: AnyOf([
    Supports(SiteFeature.login),
    Supports(SiteFeature.register),
  ]),
  AppSurface.loginAction: Supports(SiteFeature.login),
  AppSurface.registerAction: Supports(SiteFeature.register),
  AppSurface.userReviewsTab: Supports(SiteFeature.reviews),
  AppSurface.userPlaylistsTab: Supports(SiteFeature.playlists),
  AppSurface.submitReviewAction: Supports(SiteFeature.submitReview),
  AppSurface.addToPlaylistAction: AllOf([
    Supports(SiteFeature.playlists),
    Supports(SiteFeature.addWorksToPlaylist),
  ]),
  AppSurface.defaultPlaylistSetting: AllOf([
    Supports(SiteFeature.playlists),
    Supports(SiteFeature.defaultMarkTargetPlaylist),
  ]),
  AppSurface.serverSelector: AllOf([
    Supports(SiteFeature.serverSwitch),
    HasServers(),
  ]),
  AppSurface.globalFilterPage: Supports(SiteFeature.search),
});

final surfacePolicyRegistryProvider = Provider<SurfacePolicyRegistry>((ref) {
  return defaultSurfacePolicyRegistry;
});

/// Defaults to the active site and can be overridden by content-scoped pages.
final siteContextIdProvider = Provider<String>((ref) {
  return ref.watch(activeSiteIdProvider);
});

final siteContextRuntimeProvider = Provider<SiteRuntime>((ref) {
  final siteId = ref.watch(siteContextIdProvider);
  return ref.watch(siteRuntimeByIdProvider(siteId));
});

final availableSurfacesProvider = Provider<Set<AppSurface>>((ref) {
  final registry = ref.watch(surfacePolicyRegistryProvider);
  final runtime = ref.watch(siteContextRuntimeProvider);
  return registry.availableFor(runtime);
});

final surfaceAvailableProvider = Provider.family<bool, AppSurface>((
  ref,
  surface,
) {
  return ref.watch(availableSurfacesProvider).contains(surface);
});
