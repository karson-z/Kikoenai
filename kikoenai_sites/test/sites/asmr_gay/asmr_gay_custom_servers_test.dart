import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  const primary = ServerInfo(
    id: 'primary',
    baseUrl: 'https://alist-primary.example/',
    label: 'Primary',
    isDefault: true,
  );
  const backup = ServerInfo(
    id: 'backup',
    baseUrl: 'https://alist-backup.example/root/',
    label: 'Backup',
    useProxy: false,
  );

  test(
    'accepts configured AList servers and switches the HTTP base URL',
    () async {
      final client = SitesHttpClient(
        config: const RequestConfig(
          baseUrl: 'https://alist-primary.example',
          enableCookie: false,
        ),
      );
      addTearDown(client.close);
      final api = AsmrGaySiteApi(
        servers: const [primary, backup],
        initialServer: primary,
        httpClient: client,
        rawBaseUrl: null,
      );

      expect(api.currentServer, primary);
      expect(
        api
            .toFileNode(
              const FsEntry(name: '中文 音声.mp3', sign: 'signed'),
              parentPath: '/ASMR',
            )
            .mediaStreamUrl,
        'https://alist-primary.example/d/ASMR/'
        '%E4%B8%AD%E6%96%87%20%E9%9F%B3%E5%A3%B0.mp3?sign=signed',
      );

      await api.switchServer(backup);

      expect(api.currentServer, backup);
      expect(client.dio.options.baseUrl, 'https://alist-backup.example/root');
      expect(
        api
            .toFileNode(const FsEntry(name: 'track.mp3'), parentPath: '/ASMR')
            .mediaStreamUrl,
        'https://alist-backup.example/root/d/ASMR/track.mp3',
      );
    },
  );

  test('plugin resolves host-provided AList servers through Sites runtime', () {
    final runtime = SiteRuntime.create(
      AsmrGaySiteApi.plugin,
      context: SiteRuntimeContext(
        serversFor: (_) => const [primary, backup],
        initialServerFor: (_) => backup,
      ),
    );
    addTearDown(runtime.dispose);

    expect(runtime.info.servers, const [primary, backup]);
    expect(runtime.currentServer, backup);
    expect(
      runtime.httpClient!.dio.options.baseUrl,
      AsmrGaySiteApi.normalizeBaseUrl(backup),
    );
    expect((runtime.api as AsmrGaySiteApi).rawBaseUrl, isNull);
  });

  test('rejects invalid or undeclared AList servers', () {
    expect(
      () => AsmrGaySiteApi.normalizeBaseUrl(
        const ServerInfo(
          id: 'invalid',
          baseUrl: 'ftp://alist.example',
          label: 'Invalid',
        ),
      ),
      throwsFormatException,
    );

    final api = AsmrGaySiteApi(
      servers: const [primary],
      initialServer: primary,
      rawBaseUrl: null,
    );
    addTearDown(api.httpClient.close);
    expect(
      api.httpClient.dio.options.baseUrl,
      AsmrGaySiteApi.normalizeBaseUrl(primary),
    );
    expect(() => api.switchServer(backup), throwsArgumentError);
  });
}
