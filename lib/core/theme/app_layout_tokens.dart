import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

enum AppLayoutSize { compact, medium, expanded }

enum AppCardVariant {
  workGrid,
  workList,
  featuredWork,
  history,
  review,
  fileRow,
}

@immutable
class AppCardMetrics {
  const AppCardMetrics({
    required this.margin,
    required this.padding,
    required this.radius,
    required this.spacing,
    this.coverAspectRatio,
    this.coverSize,
  });

  final EdgeInsets margin;
  final EdgeInsets padding;
  final double radius;
  final double spacing;
  final double? coverAspectRatio;
  final Size? coverSize;
}

class AppLayoutTokens {
  const AppLayoutTokens._(
    this.size, {
    this.windowSize = Size.zero,
    this.isPhone = false,
  });

  final AppLayoutSize size;
  final Size windowSize;
  final bool isPhone;

  static const wideNavigationBreakpoint = 840.0;
  static const navigationRailWidth = 164.0;

  bool get useWideNavigation =>
      !isPhone && windowSize.width >= wideNavigationBreakpoint;
  bool get isPhoneLandscape => isPhone && windowSize.width > windowSize.height;
  bool get useDenseCards => isPhone || size == AppLayoutSize.compact;
  double get searchToolbarHeight => isPhoneLandscape ? 48 : 64;
  double get bottomNavigationHeight => isPhoneLandscape ? 48 : 68;
  double get miniPlayerHeight => isPhoneLandscape ? 48 : 64;

  factory AppLayoutTokens.forWindow(Size windowSize, TargetPlatform platform) {
    final mobilePlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.android;
    return AppLayoutTokens._(
      windowSize.width < 600
          ? AppLayoutSize.compact
          : windowSize.width < 1024
          ? AppLayoutSize.medium
          : AppLayoutSize.expanded,
      windowSize: windowSize,
      isPhone: mobilePlatform && windowSize.shortestSide < 600,
    );
  }

  static AppLayoutTokens of(BuildContext context) {
    final window = AppLayoutTokens.forWindow(
      MediaQuery.sizeOf(context),
      Theme.of(context).platform,
    );
    try {
      return AppLayoutTokens._switch(
        ResponsiveBreakpoints.of(context).breakpoint.name,
        window,
      );
    } on FlutterError {
      return window;
    }
  }

  factory AppLayoutTokens.forSize(AppLayoutSize size) =>
      AppLayoutTokens._(size);

  factory AppLayoutTokens._switch(String? name, AppLayoutTokens window) =>
      AppLayoutTokens._(
        switch (name) {
          'medium' => AppLayoutSize.medium,
          'expanded' => AppLayoutSize.expanded,
          _ => AppLayoutSize.compact,
        },
        windowSize: window.windowSize,
        isPhone: window.isPhone,
      );

  double get pageInset => isPhone
      ? 4
      : switch (size) {
          AppLayoutSize.compact => 4,
          AppLayoutSize.medium => 6,
          AppLayoutSize.expanded => 8,
        };

  /// 页面内容统一与首页标题对齐，纵向间距由各页面保留。
  EdgeInsets pagePadding({double top = 0, double bottom = 0}) =>
      EdgeInsets.fromLTRB(pageInset, top, pageInset, bottom);

  double get gridGap => isPhone
      ? 1
      : switch (size) {
          AppLayoutSize.compact => 1,
          AppLayoutSize.medium => 2,
          AppLayoutSize.expanded => 4,
        };

  double get sectionGap => switch (size) {
    AppLayoutSize.compact => 16,
    AppLayoutSize.medium => 24,
    AppLayoutSize.expanded => 32,
  };

  double get contentMaxWidth => switch (size) {
    AppLayoutSize.compact => double.infinity,
    AppLayoutSize.medium => 960,
    AppLayoutSize.expanded => 1200,
  };

  double get readingMaxWidth => 720;
  double get formMaxWidth => 560;

  double get workContentMaxWidth => switch (size) {
    AppLayoutSize.compact => double.infinity,
    AppLayoutSize.medium => 1120,
    AppLayoutSize.expanded => 1440,
  };

  double get radiusSmall => 4;
  double get radiusMedium => 8;
  double get radiusLarge => 12;

  double get space1 => 4;
  double get space2 => 8;
  double get space3 => 12;
  double get space4 => 16;
  double get space5 => 20;
  double get space6 => 24;
  double get space8 => 32;
  double get space10 => 40;
  double get space12 => 48;

  AppCardMetrics card(AppCardVariant variant) {
    return switch (variant) {
      AppCardVariant.workGrid => AppCardMetrics(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(space2),
        radius: radiusSmall,
        spacing: gridGap,
        coverAspectRatio: 4 / 3,
      ),
      AppCardVariant.workList => AppCardMetrics(
        margin: EdgeInsets.symmetric(
          horizontal: pageInset,
          vertical: useDenseCards ? gridGap / 2 : space1,
        ),
        padding: EdgeInsets.all(space2),
        radius: radiusMedium,
        spacing: space3,
        coverAspectRatio: 4 / 3,
        coverSize: const Size(88, 66),
      ),
      AppCardVariant.featuredWork => AppCardMetrics(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(space3),
        radius: radiusMedium,
        spacing: gridGap,
        coverAspectRatio: 4 / 3,
      ),
      AppCardVariant.history => AppCardMetrics(
        margin: EdgeInsets.symmetric(horizontal: pageInset, vertical: space2),
        padding: EdgeInsets.all(space3),
        radius: radiusMedium,
        spacing: space3,
      ),
      AppCardVariant.review => AppCardMetrics(
        margin: EdgeInsets.symmetric(horizontal: pageInset, vertical: space2),
        padding: EdgeInsets.all(space3),
        radius: radiusMedium,
        spacing: space3,
        coverAspectRatio: 4 / 3,
      ),
      AppCardVariant.fileRow => AppCardMetrics(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: space3, vertical: space2),
        radius: radiusSmall,
        spacing: space2,
        coverSize: const Size(56, 56),
      ),
    };
  }
}

extension AppLayoutContextX on BuildContext {
  AppLayoutTokens get layout => AppLayoutTokens.of(this);

  bool get isCompactLayout => layout.size == AppLayoutSize.compact;
  bool get isExpandedLayout => layout.size == AppLayoutSize.expanded;
}
