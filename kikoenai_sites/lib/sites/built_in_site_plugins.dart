import '../api/site_plugin.dart';
import 'asmr_gay/asmr_gay_site_api.dart';
import 'asmr_one/asmr_one_site_api.dart';
import 'kikoeru/kikoeru_site_api.dart';

/// Built-in site composition root.
///
/// Adding a built-in site only requires exposing its plugin here. Runtime
/// configuration remains owned by the plugin itself.
final List<SitePlugin> builtInSitePlugins = List.unmodifiable([
  AsmrOneSiteApi.plugin,
  AsmrGaySiteApi.plugin,
  KikoeruSiteApi.plugin,
]);
