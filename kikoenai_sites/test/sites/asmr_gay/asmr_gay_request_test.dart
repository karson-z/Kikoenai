// 调用 asmr.gay（Alist 文件系统型站点）的查询类接口并验证响应。
//
// 运行方式：
//   flutter test test/sites/asmr_gay/asmr_gay_request_test.dart --reporter=expanded
//
// 代理配置（asmr.gay 可能需要走代理才能访问）：
//   默认 127.0.0.1:7890，可通过环境变量覆盖：
//   - ASM_PROXY_HOST=127.0.0.1
//   - ASM_PROXY_PORT=7890
//   - ASM_PROXY_DISABLE=1   （禁用代理，直连）
//
// 本测试只调用查询类接口（GET / POST /api/fs/list 与健康检查），
// 不调用任何会修改服务端数据的接口。
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
  late AsmrGaySiteApi api;
  ServerInfo? healthyServer;

  setUpAll(() async {
    // 探测 4 个镜像，选第一个健康的服务器
    final probe = AsmrGaySiteApi(
      httpClient: _newClient(AsmrGaySiteApi.info.defaultServer!.baseUrl),
    );
    final healths = await probe.checkAllHealth(AsmrGaySiteApi.info.servers);
    _printObj('全部服务器健康检查结果', healths.map((h) => h.toString()).toList());

    final healthy = healths.where((h) => h.isHealthy).toList();
    if (healthy.isEmpty) {
      throw StateError('所有 asmr.gay 镜像均不可访问，无法跑测试');
    }
    healthyServer = AsmrGaySiteApi.info.servers.firstWhere(
      (s) => s.id == healthy.first.serverId,
    );
    _printObj('选中健康服务器', healthyServer);
  });

  setUp(() {
    api = AsmrGaySiteApi(
      httpClient: _newClient(healthyServer!.baseUrl),
      initialServer: healthyServer!,
    );
  });

  // ─── 1. 站点元信息 ──────────────────────────────────────────────

  test('dump: SiteInfo & supportedFeatures', () {
    _printObj('SiteInfo', AsmrGaySiteApi.info);
    _printObj('supportedFeatures', api.supportedFeatures.toList());
    _printObj('currentServer', api.currentServer);

    expect(AsmrGaySiteApi.info.id, 'asmr.gay');
    expect(AsmrGaySiteApi.info.servers.length, 4);
    expect(api.supports(SiteFeature.fileSystemBrowse), isTrue);
    expect(api.supports(SiteFeature.siteReadme), isTrue);
    expect(api.supports(SiteFeature.serverSwitch), isTrue);
    expect(api.supports(SiteFeature.healthCheck), isTrue);
    // asmr.gay 不支持登录 / 检索作品（与 asmr.one 区分）
    expect(api.supports(SiteFeature.login), isFalse);
    expect(api.supports(SiteFeature.search), isFalse);
  });

  // ─── 2. 健康检查 ────────────────────────────────────────────────

  test('checkHealth 单服务器返回延迟', () async {
    final health = await api.checkHealth(api.currentServer);
    _printObj('checkHealth(${api.currentServer.id})', health);

    expect(health.serverId, api.currentServer.id);
    expect(health.isHealthy, isTrue);
    expect(health.latencyMs, isNotNull);
    expect(health.latencyMs! >= 0, isTrue);
  });

  test('checkAllHealth 返回 4 个服务器结果', () async {
    final results = await api.checkAllHealth(AsmrGaySiteApi.info.servers);
    for (final h in results) {
      _printObj('checkAllHealth[${h.serverId}]', h);
    }

    expect(results.length, 4);
    // setUpAll 已验证至少一个健康
    expect(results.any((h) => h.isHealthy), isTrue);
    // 每个 serverId 都对应站点声明的镜像
    final declaredIds = AsmrGaySiteApi.info.servers.map((s) => s.id).toSet();
    for (final h in results) {
      expect(declaredIds.contains(h.serverId), isTrue);
    }
  });

  // ─── 3. 文件系统浏览（核心能力）──────────────────────────────

  test('browseFileSystem 根目录返回分类列表', () async {
    final result = await api.browseFileSystem(
      const FsListRequest(path: '/', page: 1, perPage: 30),
    );

    _printObj('根目录 total', result.total);
    _printObj(
      '根目录条目名',
      result.content.map((e) => '${e.name}${e.isDir ? '/' : ''}').toList(),
    );

    // 验证响应结构
    expect(result.total, greaterThan(0));
    expect(result.content, isNotEmpty);

    // 验证已知分类存在（用户提供的数据中包含这些目录）
    final names = result.content.map((e) => e.name).toSet();
    expect(names, containsAll(['asmr', 'asmr2', 'asmr3', 'asmr4', 'asmr5', 'asmr6']));

    // 根目录下的条目应该都是目录
    for (final entry in result.content) {
      expect(entry.isDir, isTrue, reason: '${entry.name} 应为目录');
    }

    // 验证 FsEntry 字段映射正确（snake_case → camelCase）
    final firstEntry = result.content.first;
    expect(firstEntry.name, isNotEmpty);
    // type 字段：目录应为 1
    expect(firstEntry.type, 1);
  });

  test('browseFileSystem readme 字段含站点说明', () async {
    final result = await api.browseFileSystem(
      const FsListRequest(path: '/', page: 1, perPage: 1),
    );

    _printObj('readme 长度', result.readme?.length ?? 0);
    if (result.readme != null) {
      // 只打印前 200 字符避免刷屏
      _printObj('readme 预览', result.readme!.substring(0, result.readme!.length > 200 ? 200 : result.readme!.length));
    }

    // 根据用户提供的响应数据，readme 字段应包含站点标题
    expect(result.readme, isNotNull);
    expect(result.readme!.isNotEmpty, isTrue);
    // 用户数据中 readme 包含 "ASMR基佬中心"
    expect(result.readme, contains('ASMR'));
  });

  test('getSiteReadme 直接返回 Markdown 字符串', () async {
    final readme = await api.getSiteReadme(path: '/');

    _printObj('getSiteReadme 长度', readme?.length ?? 0);

    expect(readme, isNotNull);
    expect(readme!.isNotEmpty, isTrue);
  });

  test('browseFileSystem 分页参数生效', () async {
    // 第一页取 2 条
    final page1 = await api.browseFileSystem(
      const FsListRequest(path: '/', page: 1, perPage: 2),
    );
    _printObj('page1 条目数', page1.content.length);
    expect(page1.content.length, lessThanOrEqualTo(2));

    // 第二页取 2 条
    final page2 = await api.browseFileSystem(
      const FsListRequest(path: '/', page: 2, perPage: 2),
    );
    _printObj('page2 条目数', page2.content.length);

    // 两页不能完全相同（条目名集合不同）
    final names1 = page1.content.map((e) => e.name).toSet();
    final names2 = page2.content.map((e) => e.name).toSet();
    expect(names1.intersection(names2).isEmpty, isTrue, reason: '不同页应返回不同条目');

    // 总数应一致
    expect(page2.total, page1.total);
  });

  // ─── 4. 子目录浏览（asmr 目录）──────────────────────────────

  test('browseFileSystem 子目录 /asmr 返回文件列表', () async {
    final result = await api.browseFileSystem(
      const FsListRequest(path: '/asmr', page: 1, perPage: 10),
    );

    _printObj('/asmr total', result.total);
    _printObj(
      '/asmr 条目名',
      result.content.map((e) => '${e.name}${e.isDir ? '/' : ''}').toList(),
    );

    expect(result.total, greaterThan(0));
  });

  // ─── 5. FsEntry → FileNode 转换 ────────────────────────────

  test('browseAsFileNodes 返回标记来源的 FileNode', () async {
    final result = await api.browseAsFileNodes(
      const FsListRequest(path: '/', page: 1, perPage: 30),
    );

    _printObj('FileNodes 数量', result.items.length);
    _printObj('pagination', result.pagination);

    expect(result.items, isNotEmpty);
    expect(result.pagination.totalCount, greaterThan(0));

    for (final node in result.items) {
      // 来源标记正确
      expect(node.source, NodeSource.asmrGay);
      // siteId 标记为本站点
      expect(node.siteId, 'asmr.gay');
      // remoteId 为完整路径
      expect(node.remoteId, startsWith('/'));
      expect(node.remoteId, contains(node.title));
      // path 携带完整路径
      expect(node.path, node.remoteId);
      // folderPath 为父目录（根目录下条目的 folderPath 为 /）
      expect(node.folderPath, '/');
      // 根目录条目应为 folder 类型
      expect(node.type, NodeType.folder);
      expect(node.isFolder, isTrue);
      // isAsmrGay 便捷 getter
      expect(node.isAsmrGay, isTrue);
      // isRemote 应包含 asmrGay
      expect(node.isRemote, isTrue);
    }
  });

  test('toFileNode 文件节点生成下载链接', () async {
    // 进入 /asmr 目录找一个文件节点
    final dirResult = await api.browseFileSystem(
      const FsListRequest(path: '/asmr', page: 1, perPage: 30),
    );

    // 找一个非目录条目（文件），如果没有就跳过
    FsEntry? fileEntry;
    String? parentPath;
    for (final entry in dirResult.content) {
      if (!entry.isDir) {
        fileEntry = entry;
        parentPath = '/asmr';
        break;
      }
    }

    if (fileEntry == null) {
      _printObj('toFileNode 文件测试', '跳过：/asmr 目录下未找到文件条目');
      return;
    }

    final node = api.toFileNode(fileEntry, parentPath: parentPath!);
    _printObj('文件 FileNode', node);

    // 下载链接应包含 baseUrl 与 /d/ 前缀
    expect(node.mediaDownloadUrl, isNotNull);
    expect(node.mediaDownloadUrl, contains('/d/'));
    expect(node.mediaDownloadUrl, startsWith(api.currentServer.baseUrl));

    // sign 非空时 URL 应带 ?sign=
    if (fileEntry.sign.isNotEmpty) {
      expect(node.mediaDownloadUrl, contains('?sign='));
    }

    // 文件类型应为非 folder
    expect(node.type, isNot(NodeType.folder));
  });

  test('toFileNodes 批量转换保持顺序', () async {
    final result = await api.browseFileSystem(
      const FsListRequest(path: '/', page: 1, perPage: 5),
    );

    final nodes = api.toFileNodes(
      result.content,
      parentPath: '/',
    );

    // 数量一致
    expect(nodes.length, result.content.length);
    // 顺序一致（title 与 name 对应）
    for (var i = 0; i < nodes.length; i++) {
      expect(nodes[i].title, result.content[i].name);
    }
  });

  // ─── 6. 服务器切换 ────────────────────────────────────────────

  test('switchServer 切换后 currentServer 更新', () async {
    final original = api.currentServer;
    _printObj('切换前 currentServer', original);

    // 找一个不同的服务器
    final target = AsmrGaySiteApi.info.servers.firstWhere(
      (s) => s.id != original.id,
    );
    _printObj('目标服务器', target);

    await api.switchServer(target);

    _printObj('切换后 currentServer', api.currentServer);
    expect(api.currentServer.id, target.id);
    expect(api.currentServer.baseUrl, target.baseUrl);

    // 切换回来，避免影响后续测试
    await api.switchServer(original);
    expect(api.currentServer.id, original.id);
  });

  test('switchServer 拒绝未声明的服务器', () async {
    final fakeServer = const ServerInfo(
      id: 'fake',
      baseUrl: 'https://fake.example.com',
      label: 'Fake',
    );

    expect(
      () => api.switchServer(fakeServer),
      throwsArgumentError,
    );
  });
}
