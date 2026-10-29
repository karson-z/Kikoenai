# 网络代理

支持与 Kazumi 相同的应用内手动 HTTP 代理配置、连接测试和启用开关（HTTPS 请求通过 HTTP CONNECT）。入口为「设置 → 网络代理」，站点连接失败页也可直接进入。

手动代理启用时优先于系统代理；关闭后恢复原有系统代理能力。原有站点 `useProxy=false` 强制直连、爬虫显式代理、系统绕过规则和系统代理监听全部保留。不改媒体 URL，不引入转发服务器或 ECH 依赖。

代理地址和测试地址以一个记录保存到 Hive 的 `network_proxy`，避免地址与测试/启用状态不一致。点击「保存并测试」时先保存为未启用，显式通过候选代理访问测试地址；仅 HTTP 2xx 验证成功后启用，失败保持未启用。测试和手动代理请求都不附加 `DIRECT` 后备路径，且保留正常 HTTPS 证书校验。已通过测试的配置可以直接关闭、重新启用，重启应用后恢复。

## 各链路的实现

| 链路 | 行为 |
| --- | --- |
| Dart HTTP / Dio / 图片 / WebDAV / 爬虫 | 保留现有全局 `HttpOverrides`，其 `findProxy` 读取统一有效配置：手动代理优先，否则使用系统代理；已有客户端的新连接也能跟随更新。 |
| 爬虫显式 `ScraperHttpClient.setProxy` | 保留现有显式代理；传入空值恢复默认客户端，重新继承全局代理。 |
| 站点 `useProxy=false` | 保留强制直连行为。 |
| media_kit / mpv | 在现有 `onLoadHooks` 中按待加载 URL 的协议和绕过规则设置 `http-proxy`，并读回检查。新媒体加载/重复播放/认证刷新使用当前配置。 |
| iOS 后台下载 | 启用手动代理时通过 `Config.proxy` 保存显式覆盖；关闭后清除覆盖，恢复 URLSession 默认系统代理选择。初始化下载器前同步，运行中切换需重启应用后生效，见下文。 |
| Android / Windows / macOS 后台下载 | 使用 background_downloader 已有的 `Config.proxy`；初始化前应用、变更时同步、关闭时清除。新任务/恢复任务前等待同步，失败写入会重试。 |

`ProxyService` 只初始化一次，移动端无论初始是否开启代理都注册回调；四个平台回到前台时刷新，桌面每 15 秒检查一次。读取失败保留已知配置，避免将暂时失败当成“代理已关闭”。Windows 分别读取 HTTP/HTTPS 和 ProxyOverride；macOS 读取顶层 HTTP/HTTPS、ExceptionsList、ExcludeSimpleHostnames，不混入嵌套网络接口配置。绕过规则支持主机通配符、主机端口、`<local>`、IP CIDR。

macOS Debug/Profile 和 Release 的沙盒权限增加 `com.apple.security.network.client`，保留原有沙盒、JIT、入站网络、钥匙串权限。

## 行为边界

- background_downloader 9.5.8 的 iOS 实现只在创建 URLSession 时读取代理覆盖；`Config.proxy` 后续变更只写入 UserDefaults，不重建已创建的会话。因此 iOS 后台下载需要重启应用才能可靠应用手动代理的启用、修改或关闭。设置页面已提示；不会取消已有下载或修改原生插件。
- 本次覆盖手动 HTTP 代理，不实现 PAC/WPAD 执行器、SOCKS 或代理认证。移动端沿用 native_flutter_proxy 的系统读取能力；该插件只提供一个地址，不提供完整的分协议/绕过规则。VPN/TUN 的路由仍由系统处理。
- background_downloader 9.5.8 的 `Config.proxy` 仅支持一个全局端点，无法表达按任务/协议/主机的完整规则。本次优先 HTTPS 端点、否则 HTTP；其 Android/桌面下载不支持系统绕过名单，也不使用站点 API 的 `useProxy` 开关。若需要这些语义，应先扩展插件接口，不能在不同任务间轮流修改全局配置。
- 不重启正在播放的媒体，不暂停/取消正在进行的下载。播放器在下次媒体加载时应用变更；Android/桌面后台下载在新建/恢复的连接中应用配置，iOS 的会话限制见上文。已打开的连接可能继续使用原路由。
- 系统代理保留已有的 `PROXY …; DIRECT` 候选策略；应用内手动代理使用 `PROXY …`，失败不会静默退回直连。mpv 在显式代理清空后保留其原有 FFmpeg 环境变量行为（`http_proxy` / `no_proxy`），因此设置了环境代理时，空系统配置不等于强制直连。
- 初次读取系统配置失败时尚无可用端点，会沿用初始直连状态，并在后续刷新重试。

## 应用内代理验证

使用项目 `.fvmrc` 指定的 Flutter 3.47.1，以下 34 项测试通过。新增覆盖手动代理优先、同一客户端在系统代理/手动 A/手动 B 之间切换、关闭后恢复最新系统代理、保存重启恢复、禁止未测试配置启用、测试失败不直连、iOS 下载覆盖设置/清除、设置开关、窄屏布局及连接失败页往返。保留既有 HTTPS CONNECT 证书校验、爬虫显式代理、站点直连、下载界面、图片及播放控制回归。

```sh
flutter test --no-pub --timeout 45s \
  test/core/service/proxy/system_proxy_config_test.dart test/core/service/download/download_proxy_sync_test.dart \
  test/core/service/proxy/proxy_routing_test.dart test/core/service/proxy/proxy_service_test.dart \
  test/core/service/proxy/proxy_settings_test.dart test/core/utils/scraper/scraper_http_client_test.dart \
  test/features/settings/page/proxy_settings_page_test.dart test/features/site/page/site_unavailable_page_test.dart \
  test/features/download/page/download_page_test.dart test/features/user/page/user_download_entry_test.dart \
  test/core/service/audio/audio_service_overlay_controls_test.dart \
  test/core/service/player/media_http_headers_registry_test.dart test/core/widgets/card/card_image_loading_test.dart
```

以上 34 项为本机 HTTP/TLS 测试、单元测试和 Widget 测试。原生播放器的 iOS 验证见下文；iOS 后台下载尚未联调。

## 原生播放器代理集成测试

`integration_test/player_proxy_test.dart` 直接使用应用的 `PlayerService` 和 `ProxyService`，不复制播放器的代理设置逻辑，也不模拟 mpv。测试启动本地 HTTP 代理及 HTTP/HTTPS 音频源，提供两秒 PCM WAV，并要求播放器实际解码、播放进度达到至少 100 毫秒。音视频输出设置为 null，避免测试发声。

已在 iPhone 17e / iOS 26.3 模拟器上运行，Flutter 3.47.1、原生 mpv 0.36.0，4 项全部通过：

| 用例 | 验证证据 |
| --- | --- |
| 手动代理 A → B → 关闭后跟随系统代理 | 对不可解析的 `.invalid` 媒体域名发起真实播放；对应代理收到 GET，播放器进度正常增长，mpv 属性与有效代理一致。 |
| 系统绕过规则与全部代理关闭 | 本地音频源收到请求，代理请求数量不变，mpv 的 `http-proxy` 已清空。 |
| HTTPS CONNECT | 代理收到发往本地 TLS 音频源的 CONNECT，音频源收到请求，启用证书校验并使用测试 CA 后播放成功。 |
| 手动代理不可用 | 即使音频源可直连，播放器也报错，音频源没有收到请求，未加载出媒体时长。 |

在项目目录执行（脚本优先使用 `.fvm/flutter_sdk`，也可通过 `FLUTTER_BIN` 指定 SDK）：

```sh
./tool/test_player_proxy.sh -d 732EE7D3-EC73-4FE8-9FF7-BDB01FE56C22
```

其他机器将设备 ID 替换为 `flutter devices` 中的 iOS 模拟器 ID。脚本将已有 `test/fixtures/proxy` 中公开的本地测试证书/私钥通过临时测试参数传入，不添加生产资源，不读取或改写用户设置。证书有效期及更新方法见该目录 README。本次没有修改播放器业务代码或 iOS 原生文件；以上结果证明该模拟器上的原生播放链路，真机网络和外部代理仍需另行验证。

## 历史系统代理验证记录（2026-10-16）

Flutter 3.47.1：以下 18 项相关测试通过，覆盖同一 HttpClient 的 A→B→DIRECT、带证书校验的 HTTPS CONNECT、爬虫默认继承/显式代理/恢复继承、站点显式直连、解析、刷新去重与读失败保留、下载配置串行/清除/失败重试/iOS 系统选择，以及既有下载界面、播放控制、认证头回归。

```sh
flutter test --no-pub \
  test/core/service/proxy/system_proxy_config_test.dart test/core/service/download/download_proxy_sync_test.dart \
  test/core/service/proxy/proxy_routing_test.dart test/core/service/proxy/proxy_service_test.dart \
  test/core/utils/scraper/scraper_http_client_test.dart test/features/download/page/download_page_test.dart \
  test/features/user/page/user_download_entry_test.dart test/core/service/audio/audio_service_overlay_controls_test.dart \
  test/core/service/player/media_http_headers_registry_test.dart
```

对项目 macOS 依赖指定的 libmpv v0.6.0 归档做了独立本地网络验证（非完整 Flutter 应用联调）：

- 归档 SHA-256：`84d2ad98e046e82c6dc34d8547d76c2afeaee89c0f53032773be8985c95536d6`，与依赖 Makefile 一致。
- 运行时返回 mpv 0.36.0、FFmpeg 6.0。
- 本机系统 HTTP/HTTPS 代理已开启，清空进程代理环境变量、不设置显式代理：`.invalid` 测试地址加载失败，没有命中本地代理。
- 显式设置 `http-proxy`：HTTP WAV 加载成功；HTTPS WAV 经 CONNECT 加载成功（启用证书校验并指定本地测试 CA）。
- 仅设置进程 `http_proxy`：HTTP、HTTPS 两条链路均成功。

这验证了指定 macOS 原生库的能力；Android/iOS/Windows 的原生播放器与后台下载、四个平台前后台切换/网络切换仍需设备联调，不能将主机测试视为四平台已验收。

## 调研依据

- background_downloader 9.5.8：Android TaskRunner 使用 `openConnection(proxy ?: Proxy.NO_PROXY)`；桌面下载 isolate 自行设置 `HttpClient.findProxy`；iOS URLSession 无显式覆盖时保留系统配置。
- [Apple URLSessionConfiguration.connectionProxyDictionary](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/connectionproxydictionary)
- [FFmpeg 6.0 HTTP 实现](https://github.com/FFmpeg/FFmpeg/blob/n6.0/libavformat/http.c)、[TLS 实现](https://github.com/FFmpeg/FFmpeg/blob/n6.0/libavformat/tls.c)
- [media_kit macOS 对应的原生库归档](https://github.com/media-kit/libmpv-darwin-build/releases/tag/v0.6.0)
