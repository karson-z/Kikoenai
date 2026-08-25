import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../service/site/site_api_provider.dart';

class SiteFeatureGate extends ConsumerWidget {
  const SiteFeatureGate({
    super.key,
    required this.feature,
    required this.child,
  });

  final SiteFeature feature;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(siteSupportsProvider(feature))) return child;
    return const Scaffold(body: Center(child: Text('当前站点不支持此功能')));
  }
}
