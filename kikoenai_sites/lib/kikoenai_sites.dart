/// kikoenai_sites: 多站点 API 聚合层。
///
/// 所有站点响应模型已迁移至 [kikoenai_core]，本包只承担「多站点适配层 / Repository」职责。
/// 这里直接 re-export [kikoenai_core] 的全部公共 API，方便业务侧只依赖 kikoenai_sites。
library;

export 'package:kikoenai_core/kikoenai_core.dart';
