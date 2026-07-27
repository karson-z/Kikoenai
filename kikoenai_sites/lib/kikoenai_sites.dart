/// kikoenai_sites: 多站点 API 聚合层。
///
/// 所有站点响应模型已迁移至 [kikoenai_core]，本包只承担「多站点适配层 / Repository」职责。
/// 这里直接 re-export [kikoenai_core] 的全部公共 API，方便业务侧只依赖 kikoenai_sites。
///
/// 另外提供 [network] 模块，封装基于 dio 的 HTTP 客户端与拦截器链。
library;

export 'package:kikoenai_core/kikoenai_core.dart';

// ---- Site API 抽象层 ----
export 'api/listen_event_type.dart';
export 'api/server_health.dart';
export 'api/server_info.dart';
export 'api/site_api.dart';
export 'api/site_feature.dart';
export 'api/site_info.dart';
export 'api/site_manager.dart';

// ---- Network ----
export 'network/cookie_manager.dart';
export 'network/exception.dart';
export 'network/http_client.dart';
export 'network/interceptor.dart';
export 'network/request_config.dart';
export 'network/unauthorized_interceptor.dart';

// ---- Scraper（外部站点元数据爬取） ----
export 'scraper/dlsite_scraper.dart';
export 'scraper/hvdb_scraper.dart';
export 'scraper/scraper_http_client.dart';
export 'scraper/scraper_utils.dart';

// ---- 站点实现 ----
export 'sites/asmr_one/asmr_one_site_api.dart';
