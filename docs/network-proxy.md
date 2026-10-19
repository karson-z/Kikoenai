# 系统网络代理

目前复用系统手动 HTTP 代理（HTTPS 请求通过 HTTP CONNECT）。不新增应用内代理设置、不改媒体 URL、不引入转发服务器。

## 各链路的实现

| 链路 | 行为 |
| --- | --- |
| Dart HTTP / Dio / 图片 / WebDAV / 爬虫 | 全局 `HttpOverrides` 的 `findProxy` 在每次新连接时读取当前配置；已有客户端也能跟随更新。 |
| 爬虫显式 `ScraperHttpClient.setProxy` | 保留现有显式代理；传入空值恢复默认客户端，重新继承全局代理。 |
| 站点 `useProxy=false` | 保留强制直连行为。 |
| media_kit / mpv | 在现有 `onLoadHooks` 中按待加载 URL 的协议和绕过规则设置 `http-proxy`，并读回检查。新媒体加载/重复播放/认证刷新使用当前配置。 |
| iOS 后台下载 | 保留 URLSession 默认系统代理选择；启动下载器前清除插件持久化的显式代理覆盖。 |
| Android / Windows / macOS 后台下载 | 使用 background_downloader 已有的 `Config.proxy`；初始化前应用、变更时同步、关闭时清除。新任务/恢复任务前等待同步，失败写入会重试。 |

`ProxyService` 只初始化一次，移动端无论初始是否开启代理都注册回调；四个平台回到前台时刷新，桌面每 15 秒检查一次。读取失败保留已知配置，避免将暂时失败当成“代理已关闭”。Windows 分别读取 HTTP/HTTPS 和 ProxyOverride；macOS 读取顶层 HTTP/HTTPS、ExceptionsList、ExcludeSimpleHostnames，不混入嵌套网络接口配置。绕过规则支持主机通配符、主机端口、`<local>`、IP CIDR。

macOS Debug/Profile 和 Release 的沙盒权限增加 `com.apple.security.network.client`，保留原有沙盒、JIT、入站网络、钥匙串权限。

## 行为边界

- 本次覆盖手动 HTTP 代理，不实现 PAC/WPAD 执行器、SOCKS 或代理认证。移动端沿用 native_flutter_proxy 的系统读取能力；该插件只提供一个地址，不提供完整的分协议/绕过规则。VPN/TUN 的路由仍由系统处理。
- background_downloader 9.5.8 的 `Config.proxy` 仅支持一个全局端点，无法表达按任务/协议/主机的完整规则。本次优先 HTTPS 端点、否则 HTTP；其 Android/桌面下载不支持系统绕过名单，也不使用站点 API 的 `useProxy` 开关。若需要这些语义，应先扩展插件接口，不能在不同任务间轮流修改全局配置。
- 不重启正在播放的媒体，不暂停/取消正在进行的下载。播放器在下次媒体加载时应用变更；后台下载在新建/恢复的连接中应用配置。已打开的连接可能继续使用原路由。
- Dart 保留已有的 `PROXY …; DIRECT` 候选策略。mpv 在显式代理清空后保留其原有 FFmpeg 环境变量行为（`http_proxy` / `no_proxy`），因此设置了环境代理时，空系统配置不等于强制直连。
- 初次读取系统配置失败时尚无可用端点，会沿用初始直连状态，并在后续刷新重试。

## 验证记录（2026-10-16）

Flutter 3.47.1：以下 18 项相关测试通过，覆盖同一 HttpClient 的 A→B→DIRECT、带证书校验的 HTTPS CONNECT、爬虫默认继承/显式代理/恢复继承、站点显式直连、解析、刷新去重与读失败保留、下载配置串行/清除/失败重试/iOS 系统选择，以及既有下载界面、播放控制、认证头回归。

```sh
flutter test --no-pub \
  test/system_proxy_config_test.dart test/download_proxy_sync_test.dart \
  test/proxy_routing_test.dart test/proxy_service_test.dart \
  test/scraper_http_client_test.dart test/download_page_test.dart \
  test/user_download_entry_test.dart test/audio_service_overlay_controls_test.dart \
  test/media_http_headers_registry_test.dart
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
