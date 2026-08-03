// 调用所有查询类接口并打印响应结果（不断言）
//
// 运行方式：
//   flutter test test/sites/asmr_one/asmr_one_dump_test.dart --reporter=expanded
//
// 代理配置（asmr.one 镜像需要走代理才能访问）：
//   默认 127.0.0.1:7890，可通过环境变量覆盖：
//   - ASM_PROXY_HOST=127.0.0.1
//   - ASM_PROXY_PORT=7890
//   - ASM_PROXY_DISABLE=1   （禁用代理，直连）
//
// 本测试只调用查询类（GET）接口，不调用任何会修改服务端数据的接口
// （不调用 submitReview / addWorksToPlaylist / removeWorksFromPlaylist / login / register）
// 每个接口的响应直接 print 输出，不做断言，方便人工核对返回格式
//
import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

const String _proxyHost = String.fromEnvironment(
  'ASM_PROXY_HOST',
  defaultValue: '127.0.0.1',
);
const int _proxyPort = int.fromEnvironment(
  'ASM_PROXY_PORT',
  defaultValue: 7890,
);
const bool _proxyDisabled = bool.fromEnvironment(
  'ASM_PROXY_DISABLE',
  defaultValue: false,
);

/// 创建带代理的 HTTP client
SitesHttpClient _newClient(String baseUrl) {
  final client = SitesHttpClient(
    config: RequestConfig(
      baseUrl: baseUrl,
      enableLogger: false,
      enableCookie: false,
    ),
  );
  if (!_proxyDisabled) {
    client.dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final httpClient = HttpClient()
          ..findProxy = (uri) => 'PROXY $_proxyHost:$_proxyPort';
        return httpClient;
      },
      validateCertificate: (_, __, ___) => true,
    );
  }
  return client;
}

/// 简单的 JSON 缩进打印
void _printObj(String tag, Object? obj) {
  // ignore: avoid_print
  print('━━━ $tag ━━━');
  // ignore: avoid_print
  print(obj);
  // ignore: avoid_print
  print('');
}

void main() {
  late AsmrOneSiteApi api;
  ServerInfo? healthyServer;

  setUpAll(() async {
    // 探测 4 个镜像，选第一个健康的服务器
    final probe = AsmrOneSiteApi(
      httpClient: _newClient('https://api.asmr-200.com/api'),
    );
    final healths = await probe.checkAllHealth(AsmrOneSiteApi.info.servers);
    _printObj('全部服务器健康检查结果', healths.map((h) => h.toString()).toList());

    final healthy = healths.where((h) => h.isHealthy).toList();
    if (healthy.isEmpty) {
      throw StateError('所有 asmr.one 镜像均不可访问，无法跑测试');
    }
    healthyServer = AsmrOneSiteApi.info.servers.firstWhere(
      (s) => s.id == healthy.first.serverId,
    );
    _printObj('选中健康服务器', healthyServer);
  });

  setUp(() {
    api = AsmrOneSiteApi(
      httpClient: _newClient(healthyServer!.baseUrl),
      initialServer: healthyServer!,
    );
  });

  // ─── 1. 站点元信息 ──────────────────────────────────────────────

  test('dump: SiteInfo & supportedFeatures', () {
    _printObj('SiteInfo', AsmrOneSiteApi.info);
    _printObj('supportedFeatures', api.supportedFeatures.toList());
    _printObj('currentServer', api.currentServer);
  });

  // ─── 2. 健康检查 ────────────────────────────────────────────────

  test('dump: checkHealth 单服务器', () async {
    final health = await api.checkHealth(api.currentServer);
    _printObj('checkHealth(${api.currentServer.id})', health);
  });

  test('dump: checkAllHealth 全部服务器', () async {
    final results = await api.checkAllHealth(AsmrOneSiteApi.info.servers);
    for (final h in results) {
      _printObj('checkAllHealth[${h.serverId}]', h);
    }
  });

  // ─── 3. 检索类 ─────────────────────────────────────────────────

  test('dump: searchWorks 无关键字', () async {
    try {
      final result = await api.searchWorks(
        const SearchWorksRequest(page: 1, pageSize: 5),
      );
      _printObj('searchWorks.items.length', result.items.length);
      _printObj('searchWorks.pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('searchWorks.items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('searchWorks 异常', '$e\n$st');
    }
  });

  test('dump: searchWorks 带关键字', () async {
    try {
      final result = await api.searchWorks(
        const SearchWorksRequest(keyword: 'ASMR', page: 1, pageSize: 5),
      );
      _printObj('searchWorks(keyword=ASMR).items.length', result.items.length);
      _printObj('searchWorks(keyword=ASMR).pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('searchWorks(keyword=ASMR).items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('searchWorks(keyword=ASMR) 异常', '$e\n$st');
    }
  });

  test('dump: searchWorks 带排序参数', () async {
    try {
      final result = await api.searchWorks(
        const SearchWorksRequest(
          page: 1,
          pageSize: 3,
          order: 'release',
          sort: 'desc',
        ),
      );
      _printObj(
        'searchWorks(order=release,sort=desc).items.length',
        result.items.length,
      );
      _printObj(
        'searchWorks(order=release,sort=desc).pagination',
        result.pagination,
      );
      for (final w in result.items) {
        _printObj(
          '  Work(id=${w.id})',
          'title=${w.title} release=${w.release}',
        );
      }
    } catch (e, st) {
      _printObj('searchWorks(order,sort) 异常', '$e\n$st');
    }
  });

  test('dump: getPopularWorks', () async {
    try {
      final result = await api.getPopularWorks(
        const SearchWorksRequest(page: 1, pageSize: 5),
      );
      _printObj('getPopularWorks.items.length', result.items.length);
      _printObj('getPopularWorks.pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('getPopularWorks.items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('getPopularWorks 异常', '$e\n$st');
    }
  });

  test('dump: getRecommendedWorks 无 uuid', () async {
    try {
      final result = await api.getRecommendedWorks(
        const SearchWorksRequest(page: 1, pageSize: 5),
      );
      _printObj('getRecommendedWorks(无uuid).items.length', result.items.length);
      _printObj('getRecommendedWorks(无uuid).pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('getRecommendedWorks(无uuid).items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('getRecommendedWorks(无uuid) 异常', '$e\n$st');
    }
  });

  test('dump: getRecommendedWorks 带 uuid', () async {
    try {
      final result = await api.getRecommendedWorks(
        const SearchWorksRequest(
          page: 1,
          pageSize: 5,
          recommenderUuid: '00000000-0000-0000-0000-000000000000',
        ),
      );
      _printObj('getRecommendedWorks(带uuid).items.length', result.items.length);
      _printObj('getRecommendedWorks(带uuid).pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('getRecommendedWorks(带uuid).items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('getRecommendedWorks(带uuid) 异常', '$e\n$st');
    }
  });

  test('dump: getCircles', () async {
    try {
      final circles = await api.getCircles();
      _printObj('getCircles.length', circles.length);
      if (circles.isNotEmpty) {
        _printObj('getCircles[0]', circles.first);
        _printObj('getCircles[1]', circles.length > 1 ? circles[1] : null);
      }
    } catch (e, st) {
      _printObj('getCircles 异常', '$e\n$st');
    }
  });

  test('dump: getTags', () async {
    try {
      final tags = await api.getTags();
      _printObj('getTags.length', tags.length);
      if (tags.isNotEmpty) {
        _printObj('getTags[0]', tags.first);
        _printObj('getTags[1]', tags.length > 1 ? tags[1] : null);
      }
    } catch (e, st) {
      _printObj('getTags 异常', '$e\n$st');
    }
  });

  test('dump: getVas', () async {
    try {
      final vas = await api.getVas();
      _printObj('getVas.length', vas.length);
      if (vas.isNotEmpty) {
        _printObj('getVas[0]', vas.first);
        _printObj('getVas[1]', vas.length > 1 ? vas[1] : null);
      }
    } catch (e, st) {
      _printObj('getVas 异常', '$e\n$st');
    }
  });

  // ─── 4. 详情与音轨 ─────────────────────────────────────────────

  // 用 getPopularWorks 抓一个真实 workId（searchWorks 接口现在需要 token）
  int? sampleWorkId;

  test('dump: 抓取真实 workId', () async {
    try {
      final result = await api.getPopularWorks(
        const SearchWorksRequest(page: 1, pageSize: 1),
      );
      if (result.items.isNotEmpty) {
        sampleWorkId = result.items.first.id;
        _printObj('抓取到的 workId', sampleWorkId);
        _printObj('对应 Work', result.items.first);
      } else {
        _printObj('抓取 workId', 'getPopularWorks 返回空列表');
      }
    } catch (e, st) {
      _printObj('抓取 workId 异常', '$e\n$st');
    }
  });

  test('dump: getWorkDetail', () async {
    if (sampleWorkId == null) {
      _printObj('getWorkDetail', '跳过：未抓到 workId');
      return;
    }
    try {
      final work = await api.getWorkDetail(sampleWorkId!.toString());
      _printObj('getWorkDetail($sampleWorkId)', work);
    } catch (e, st) {
      _printObj('getWorkDetail 异常', '$e\n$st');
    }
  });

  test('dump: getWorkTracks', () async {
    if (sampleWorkId == null) {
      _printObj('getWorkTracks', '跳过：未抓到 workId');
      return;
    }
    try {
      final tracks = await api.getWorkTracks(sampleWorkId!.toString());
      _printObj('getWorkTracks($sampleWorkId).length', tracks.length);

      // 递归打印音轨树结构（限制深度避免输出过长）
      void dumpNode(FileNode node, int depth) {
        final indent = '  ' * depth;
        _printObj(
          '${indent}FileNode',
          'title=${node.title} '
              'type=${node.type} source=${node.source} '
              'workId=${node.workId} '
              'mediaStreamUrl=${node.mediaStreamUrl != null ? "<非空>" : "null"} '
              'duration=${node.duration} size=${node.size} '
              'children=${node.children?.length ?? 0}',
        );
        for (final child in node.children ?? const <FileNode>[]) {
          dumpNode(child, depth + 1);
        }
      }

      for (final node in tracks.take(3)) {
        dumpNode(node, 0);
      }
    } catch (e, st) {
      _printObj('getWorkTracks 异常', '$e\n$st');
    }
  });

  // ─── 5. 评论查询（GET /review，需要 token）────────────────────

  test('dump: fetchReviews', () async {
    try {
      final result = await api.fetchReviews(
        const ReviewQueryParams(page: 1, order: 'updated_at', sort: 'desc'),
      );
      _printObj('fetchReviews.items.length', result.items.length);
      _printObj('fetchReviews.pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('fetchReviews.items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('fetchReviews 异常', '$e\n$st');
    }
  });

  // ─── 6. 收藏查询（需要 token）─────────────────────────────────

  test('dump: fetchPlaylists', () async {
    try {
      final result = await api.fetchPlaylists(page: 1, pageSize: 5);
      _printObj('fetchPlaylists.items.length', result.items.length);
      _printObj('fetchPlaylists.pagination', result.pagination);
      if (result.items.isNotEmpty) {
        _printObj('fetchPlaylists.items[0]', result.items.first);
      }
    } catch (e, st) {
      _printObj('fetchPlaylists 异常', '$e\n$st');
    }
  });

  test('dump: fetchDefaultMarkTargetPlaylist', () async {
    try {
      final playlist = await api.fetchDefaultMarkTargetPlaylist();
      _printObj('fetchDefaultMarkTargetPlaylist', playlist);
    } catch (e, st) {
      _printObj('fetchDefaultMarkTargetPlaylist 异常', '$e\n$st');
    }
  });

  test('dump: fetchPlaylistWorks 无效 id', () async {
    try {
      final result = await api.fetchPlaylistWorks(
        playlistId: 'invalid-id-for-test',
        page: 1,
      );
      _printObj(
        'fetchPlaylistWorks(invalid).items.length',
        result.items.length,
      );
      _printObj('fetchPlaylistWorks(invalid).pagination', result.pagination);
    } catch (e, st) {
      _printObj('fetchPlaylistWorks(invalid) 异常', '$e\n$st');
    }
  });

  // ─── 7. 服务器切换 dump（不实际改服务端状态） ──────────────────

  test('dump: currentServer & 服务器列表', () {
    _printObj('currentServer', api.currentServer);
    _printObj('servers 列表', AsmrOneSiteApi.info.servers);
  });
}
