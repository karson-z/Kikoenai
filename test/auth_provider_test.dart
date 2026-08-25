import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/auth/provider/auth_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

class _DeferredLoginApi extends SiteApi {
  final Completer<AuthResponse> loginResult = Completer<AuthResponse>();

  @override
  Set<SiteFeature> get supportedFeatures => const {SiteFeature.login};

  @override
  Future<AuthResponse> login(LoginParams loginParams) => loginResult.future;
}

class _NoAuthApi extends SiteApi {
  @override
  Set<SiteFeature> get supportedFeatures => const {};
}

SiteRuntime _runtime(String siteId, SiteApi api) {
  return SiteRuntime.fromApi(
    info: SiteInfo(id: siteId, name: siteId, version: '1.0.0'),
    api: api,
  );
}

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'kikoenai_auth_test_',
    );
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(AuthResponseAdapter().typeId)) {
      Hive.registerAdapter(AuthResponseAdapter());
    }
    AppStorage.authBox = await Hive.openBox<AuthResponse>('auth_test');
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings_test');
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('login result updates only the site that started the request', () async {
    final siteOneApi = _DeferredLoginApi();
    final registry = SiteRegistry()
      ..registerRuntime(_runtime('site.one', siteOneApi))
      ..registerRuntime(_runtime('site.two', _NoAuthApi()));
    final container = ProviderContainer(
      overrides: [
        siteRegistryProvider.overrideWithValue(registry),
        initialActiveSiteIdProvider.overrideWithValue('site.one'),
        siteSelectionPersistenceProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    final loginFuture = container
        .read(authNotifierProvider.notifier)
        .login('alice', 'password');

    await container.read(activeSiteIdProvider.notifier).activate('site.two');
    await container.read(authNotifierProvider.future);

    siteOneApi.loginResult.complete(
      const AuthResponse(
        user: User(name: 'alice'),
        token: 'token-a',
      ),
    );
    await loginFuture;

    final activeAuth = await container.read(authNotifierProvider.future);
    final siteOneSession = CacheService.instance.getAuthSession(
      siteId: 'site.one',
    );
    expect(activeAuth.isLoggedIn, isFalse);
    expect(siteOneSession?.token, 'token-a');
  });
}
