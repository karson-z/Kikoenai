# Kikoenai Code Wiki

> **Kikoenai（聴こえない）** —— 专为同人音声爱好者打造的跨平台播放器，让您随时随地沉浸在喜爱作品的世界里。
>
> 本文档由源码静态分析自动整理，覆盖项目整体架构、模块职责、关键类与函数、依赖关系以及运行方式。

---

## 目录

1. [项目概览](#1-项目概览)
2. [技术栈与依赖](#2-技术栈与依赖)
3. [整体架构](#3-整体架构)
4. [目录结构](#4-目录结构)
5. [模块职责详解](#5-模块职责详解)
6. [关键类与函数说明](#6-关键类与函数说明)
7. [数据流与状态管理](#7-数据流与状态管理)
8. [模块依赖关系](#8-模块依赖关系)
9. [项目运行方式](#9-项目运行方式)
10. [平台与原生配置](#10-平台与原生配置)

---

## 1. 项目概览

| 项目         | 说明                                                                                  |
| ---------- | ----------------------------------------------------------------------------------- |
| **应用名称**   | Kikoenai（聴こえない）                                                                      |
| **版本**     | 1.0.4+1                                                                             |
| **包名**     | `kikoenai`（Android Application ID：`com.karson.kikoenai`）                            |
| **Dart SDK** | `3.11.5`                                                                            |
| **框架**     | Flutter 3.x（Material 3）                                                             |
| **支持平台**   | Android、iOS、Windows、macOS、Web                                                       |
| **核心定位**   | 同人音声作品的发现、管理与播放器；支持在线流媒体、本地媒体库、视频播放、桌面悬浮歌词、下载等                                      |
| **后端服务**   | 默认对接 `https://api.asmr-200.com`（含多镜像节点自动优选：asmr-200 / asmr.one / asmr-100 / asmr-300） |

### 核心功能

- **无缝收听体验**：从上次停下的位置继续（播放列表、音量、秒级进度自动持久化），自动记录收听历史。
- **作品发现与管理**：分类、标签、声优多维度探索；作品封面、详情、文件列表的优雅展示。
- **个性化空间**：浅色/深色主题切换、自定义主题色与字体、缓存管理。
- **本地音视频播放**：扫描本地文件路径，提供本地媒体库的解析与播放。
- **桌面悬浮歌词**：基于 `flutter_overlay_window` 的独立悬浮窗入口。
- **元数据爬取**：从 DLSite / HVDB 抓取作品元数据补全本地信息。

---

## 2. 技术栈与依赖

### 2.1 核心框架与状态管理

| 依赖                          | 版本          | 用途                            |
| --------------------------- | ----------- | ----------------------------- |
| `flutter_riverpod`          | ^3.0.3      | 状态管理（核心，Notifier / Provider） |
| `go_router`                 | ^16.0.0     | 声明式路由（StatefulShellRoute 分支导航）|
| `hive_ce` / `hive_ce_flutter` | ^2.15.1 / ^2.3.3 | 本地持久化（TypeAdapter + 强类型 Box）  |
| `freezed_annotation` / `freezed` | ^3.0.0 | 不可变模型生成                       |
| `json_annotation` / `json_serializable` | ^4.9.0 / ^6.7.1 | JSON 序列化                |
| `equatable`                 | ^2.0.5      | 值对象相等性比较                      |

### 2.2 网络与数据

| 依赖                          | 用途                |
| --------------------------- | ----------------- |
| `dio` (^5.9.0)              | HTTP 客户端（拦截器、超时、健康检查） |
| `cached_network_image_ce`   | 网络图片缓存            |
| `flutter_cache_manager`     | 通用文件缓存             |
| `html`                      | HTML 解析（DLSite 爬虫） |
| `background_downloader`     | 后台下载（断点续传、批量、分组通知） |

### 2.3 媒体与播放

| 依赖                          | 用途                                  |
| --------------------------- | ----------------------------------- |
| `media_kit` / `media_kit_video` / `media_kit_libs_video` | 底层基于 mpv 的音视频播放核心（含 VideoController） |
| `audio_service`             | 系统级音频服务（后台播放、通知栏、锁屏控制、音频焦点）         |
| `audio_session`             | 音频会话与中断管理                           |
| `rxdart`                    | 响应式流（播放状态合并/去重）                     |
| `flutter_lyric` (git ref)   | 歌词逐行渲染与滚动                           |
| `flutter_overlay_window`    | Android 桌面悬浮窗（独立 isolate 入口）        |

### 2.4 平台与系统

| 依赖                          | 用途                              |
| --------------------------- | ------------------------------- |
| `window_manager`            | 桌面窗口控制（大小、全屏、标题栏）               |
| `tray_manager`              | 系统托盘                            |
| `permission_handler`        | 运行时权限申请                         |
| `device_info_plus`          | 设备信息（断点判断 mobile/desktop）        |
| `path_provider`             | 平台目录定位（下载/文档/支持目录）              |
| `file_picker`               | 文件/文件夹选择                         |
| `open_filex`                | 打开本地文件                          |
| `native_flutter_proxy`      | 系统代理读取                          |
| `back_button_interceptor`   | Android 返回键拦截                   |
| `disk_space_2`              | 磁盘空间查询                          |

### 2.5 UI 与工具

| 依赖                          | 用途                  |
| --------------------------- | ------------------- |
| `extended_image`            | 图片缩放/预览             |
| `google_fonts`              | 字体加载                |
| `lottie`                    | 加载动画                |
| `wolt_modal_sheet`          | 模态底部菜单              |
| `flutter_slidable`          | 列表项滑动操作             |
| `flutter_colorpicker`       | 主题色选择               |
| `palette_generator_master`  | 封面主色提取              |
| `archive`                   | 压缩包解析               |
| `charset_converter`         | 编码转换（日文文件名）         |
| `watcher`                   | 文件系统监听              |
| `uuid` / `crypto`           | 唯一标识 / 哈希           |

### 2.6 开发依赖

- `build_runner` —— 代码生成驱动
- `hive_ce_generator` —— Hive Adapter 生成
- `riverpod_lint` —— Riverpod 规则检查
- `flutter_lints` —— 默认 lint 规则

---

## 3. 整体架构

Kikoenai 采用 **Feature-First 分层架构** + **Riverpod 状态管理** + **Hive 本地优先存储** 的组合，整体可分为五层：

```
┌─────────────────────────────────────────────────────────────┐
│  入口层 (Entry Layer)                                          │
│  main.dart / overlayMain()                                    │
│  → 初始化 MediaKit / AppStorage / AudioService / ProxyService │
│  → 服务器优选 / 桌面窗口 / 启动本地媒体同步                            │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  表现层 (Presentation Layer) —— lib/features/**             │
│  page / widget / provider(Notifier) / viewmodel / state      │
│  按"功能特性"切分：album / player / local_media / auth ...      │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  核心服务层 (Core Service Layer) —— lib/core/service/**      │
│  audio / player / file / download / cache / lyrics / proxy  │
│  permission —— 单例服务，封装跨特性的业务能力                          │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  数据/基础设施层 (Data & Infra) —— lib/core/storage / utils    │
│  Hive 存储 / ApiClient(Dio) / Scraper / Theme / Logger       │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  平台层 (Platform) —— android / ios / windows / macos / web │
│  原生配置 / mpv 库 / 悬浮窗 / 系统托盘                                 │
└─────────────────────────────────────────────────────────────┘
```

### 架构要点

1. **Feature-First 切分**：`lib/features/<feature>/` 内部按 `data/`（model + service/repository）与 `presentation/`（page + provider + widget + state）子分层，特性之间通过 Riverpod Provider 解耦。
2. **本地优先**：所有用户态数据（认证、历史、播放器状态、扫描结果、设置）均落 Hive Box，应用冷启动即可恢复，弱网/离线可用。
3. **单例服务**：`AudioServiceSingleton`、`PlayerService`、`FileScannerService`、`DownloadService`、`CacheService`、`ProxyService` 均为单例，生命周期与应用一致。
4. **路由集中化**：`goRouterProvider` 用 `StatefulShellRoute.indexedStack` 实现底部导航的分支保活，配合 `SlideRightTransitionPage` 统一转场动画。
5. **双入口**：`main()` 为主 App 入口；`overlayMain()`（标注 `@pragma("vm:entry-point")`）为桌面悬浮歌词的独立 isolate 入口。

---

## 4. 目录结构

```
flutter-framework/
├── lib/
│   ├── main.dart                  # 主入口 + overlayMain() 悬浮窗入口
│   ├── app/app.dart               # MyApp 根 Widget
│   ├── config/                    # 全局配置
│   │   ├── app_version_config.dart
│   │   ├── environment_config.dart # 服务器优选
│   │   ├── navigation_item.dart
│   │   └── work_layout_config.dart # 响应式布局参数
│   ├── core/                      # 核心层（跨特性）
│   │   ├── adapter/               # Hive TypeAdapter
│   │   ├── common/                # 异常 / 分页 / PageResult
│   │   ├── constants/             # 常量
│   │   ├── enums/                 # 枚举（进度/语言/播放/排序...）
│   │   ├── model/                 # 共享模型（FileNode / Lyric / Queue）
│   │   ├── routes/                # GoRouter 配置
│   │   ├── service/               # 服务单例
│   │   │   ├── audio/             # AudioServiceSingleton + MyAudioHandler
│   │   │   ├── player/            # PlayerService（media_kit 封装）
│   │   │   ├── file/              # 文件扫描/同步/监听
│   │   │   ├── download/          # 后台下载
│   │   │   ├── cache/             # CacheService
│   │   │   ├── lyrics/            # 歌词解析/匹配/搜索
│   │   │   ├── permission/
│   │   │   └── proxy/
│   │   ├── storage/               # Hive Box 与 Key
│   │   ├── theme/                 # 主题/字体/颜色
│   │   ├── utils/                 # 工具（network/scraper/log/data/...）
│   │   └── widgets/               # 通用 Widget 库
│   └── features/                  # 功能特性（Feature-First）
│       ├── album/                 # 作品（列表/详情/分类作品）
│       ├── auth/                  # 登录/注册
│       ├── category/              # 分类
│       ├── download/              # 下载管理
│       ├── history/               # 收听历史
│       ├── local_media/           # 本地媒体库扫描
│       ├── log/                   # 日志查看
│       ├── marked/                # 在线标记/评分
│       ├── overly-lyrics/         # 桌面悬浮歌词
│       ├── player/                # 播放器（核心）
│       ├── playlist/              # 播放列表
│       ├── search/                # 搜索
│       ├── settings/              # 设置
│       ├── user/                  # 用户中心
│       └── about/                 # 关于
├── android/ ios/ macos/ windows/ web/  # 平台工程
├── assets/                        # 图片 + Lottie 动画
├── fast/                          # 原生库（mpv / ANGLE / jar）
├── test/                          # 单元测试
└── pubspec.yaml / analysis_options.yaml / distribute_options.yaml
```

---

## 5. 模块职责详解

### 5.1 入口与配置

#### `lib/main.dart`

应用冷启动入口，按顺序完成关键初始化：

1. `WidgetsFlutterBinding.ensureInitialized()` + `MediaKit.ensureInitialized()`
2. 设置透明状态栏 + edgeToEdge 沉浸式
3. `AppStorage.init()` —— 初始化所有 Hive Box
4. `AudioServiceSingleton.init()` —— 注册系统音频服务
5. `ProxyService.init()` —— 读取系统代理
6. `DownloadService.init()` —— 下载目录与 `FileDownloader` 配置
7. `EnvironmentConfig.selectBestServer()` —— 并发探测多镜像节点，2.5s 缓存校验 + 5s 全局优选兜底
8. `setupDesktopWindow()` —— 桌面窗口初始化
9. `LocalMediaSyncScheduler.instance.runStartupCheck()` —— 启动期本地媒体静默同步（unawaited）
10. `runApp(ProviderScope(child: MyApp()))`

`overlayMain()` 为悬浮窗独立入口，仅初始化绑定与 Hive，运行 `_OverlayApp`（透明背景 + `LyricsOverlayContent`）。

#### `lib/app/app.dart` — `MyApp`

`ConsumerWidget`，构建 `MaterialApp.router`：
- 监听 `themeNotifierProvider` 取主题状态
- 监听 `goRouterProvider` 取路由配置
- 若开启桌面歌词则挂起 `lyricsControllerProvider` 监听
- 启动时拉取默认"快速收藏"目标播放列表

#### `lib/config/`

| 文件                       | 职责                                                                |
| ------------------------ | ----------------------------------------------------------------- |
| `app_version_config.dart` | 版本号、应用名、GitHub 主页、在线升级接口                                          |
| `environment_config.dart` | 服务器候选列表 + `selectBestServer()` 优选 + `serverSettingsProvider` 手动切换 |
| `navigation_item.dart`    | 主导航项（首页/分类/本地媒体/我的）                                              |
| `work_layout_config.dart` | 按 `DeviceType`（mobile/tablet/laptop/desktop）返回卡片/列表布局的列数与间距       |

### 5.2 核心服务层（`lib/core/service/`）

#### `audio/` — 系统音频服务

- **`AudioServiceSingleton`**：单例，`init()` 通过 `AudioService.init` 构造 `MyAudioHandler`，配置 Android 通知渠道。
- **`MyAudioHandler extends BaseAudioHandler`**：桥接 `audio_service` 与底层 `media_kit` 的 `Player`。
  - 构造期完成：mpv 日志监听、播放器参数注入（`hr-seek`、`scaletempo2`、Android `ao` 模式）、`AudioSession` 配置、播放事件 / 时长 / 进度 / 错误流订阅。
  - 实现队列管理：`loadPlaylist` / `addQueueItem` / `removeQueueItemAt` / `clearPlaylist` / `skipToNext` / `skipToPrevious`（含 shuffle / repeat 逻辑）。
  - `customAction` 支持 `toggleVideoDecoding`（纯音频模式）与 `reorderQueue`（队列重排）。

#### `player/` — 播放核心

- **`PlayerService`**（单例）：持有全局唯一 `media_kit` 的 `Player`（`logLevel: debug`，`bufferSize: 32MB`）与懒加载的 `VideoController`。
  - `toggleVideoDecoding(bool)` —— 切换视频轨道（`VideoTrack.auto()` / `no()`）实现纯音频节能。
  - `dispose()` —— 释放底层资源。

#### `file/` — 本地媒体扫描

- **`FileScannerService`**（单例）：扫描入口 `startScan(ScanTarget)`，先加载缓存 → 判定是否需要静默同步（基于 `localMediaAutoSyncEnabled` + 阈值小时数）→ 调用 `FileScanSyncEngine` 同步磁盘 → 通过 `StreamController<FileScannerResult>` 广播结果（phase：cacheLoaded / syncSkipped / syncCompleted / statusUpdated）。
- **`FileScanSyncEngine`**：实际同步磁盘与内存索引的差异合并。
- **`FileScannerStorage`**：按 `rootPath` + `scanMode` 读写 Hive 中的扁平 `FileNode`。
- **`FileWatchService`**：基于 `watcher` 包的文件系统监听。
- **`LocalMediaSyncScheduler`**（单例）：启动期与定时静默同步调度。
- **`ArchiveService`**：压缩包内文件列表解析。

#### `download/` — 后台下载

- **`DownloadService`**（单例，基于 `background_downloader`）：
  - `init()` 决定保存路径（iOS 用 Documents，其他用 Downloads，兜底 ApplicationSupport），创建 `kikoenaiDownload` 目录。
  - `enqueueBatch(...)` —— 递归遍历 `FileNode` 树构建 `DownloadTask` 列表（保留相对路径），按作品 id 分目录，注册分组回调与通知。
  - 控制：`pauseTask` / `resumeTask` / `pauseAll` / `resumeAll` / `cancel` / `delFileAndRecord` / `deleteTasksByGroup`。
  - 查询：`getDownloadingTasks` / `getCompletedTasks` / `getAllTasks`（自动清理"已完成但文件缺失"的脏记录）。
  - 暴露 `progressStream` / `statusStream` 供 UI 订阅。

#### `cache/` — 缓存服务

- **`CacheService`**（单例）：统一封装 Hive 读写，是所有上层模块访问本地状态的门面。
  - 服务器 host 持久化、推荐 UUID 生成、认证会话、搜索历史（上限 20）、播放器状态、扫描根路径。
  - 带过期包装的选项缓存（tags / vas / circles，默认 1 天）。
  - 快速收藏目标播放列表的存取。

#### `lyrics/` — 歌词

- `LyricsParseService` / `MatchLyricsService` / `SearchLyricsService`：歌词解析、本地匹配、在线搜索。

#### `permission/` 与 `proxy/`

- `PermissionService` / `PermissionProvider`：运行时权限统一申请。
- `ProxyService`（单例）：读取系统代理并注入到 Dio。

### 5.3 数据/基础设施层（`lib/core/`）

#### `storage/` — Hive 存储

- **`AppStorage`**：所有 Hive Box 的强类型容器。
  - `init()` 注册全部 TypeAdapter（17 个），并行打开 9 个 Box：`auth` / `history` / `playerState` / `settings` / `scanner` / `scraper` / `lyricsMatch` / `globalFilterTags` / `scanTarget`。
  - `_openBox<T>`：防御性打开，Box 损坏时自动关闭→删盘→重建。
  - `backupBox` / `getBoxSize` / `clearBox`：备份、计量、清理。
- **`StorageKeys`**：所有 Hive Key 常量集中定义（含前缀规则 `path_` / `item_`、包装字段 `val` / `exp`）。
- **`hive_box.dart`**：`BoxNames` 常量。

#### `utils/network/` — `ApiClient`

- 单例 `ApiClient.instance`，封装 `Dio`：
  - 默认 baseUrl 取自 `EnvironmentConfig`，10s 超时。
  - 拦截器统一注入 `Referer`/`Origin`（asmr.one）、`Authorization: Bearer <token>`（token 来自 `CacheService.getAuthSession()`）。
  - 401 自动 Toast 提示并提供"去登录"跳转。
  - 泛型 `_request<T>` 把异常映射为 `GlobalException`。
  - `checkHealth(domain)` —— 3s 短超时的健康检查，供服务器优选使用。
  - `getBytes(...)` —— 字节流下载（responseType: bytes）。

#### `utils/scraper/` — 元数据爬虫

- **`DlSiteScraper`**：从 DLSite 抓取作品元数据。
  - `scrapeStatic(id, language)` —— 解析 HTML 工作页（标题/社团/年龄/发售日/系列/标签/声优），声优兜底走 `HvdbScraper`。
  - `scrapeDynamic(id)` —— 拉 AJAX JSON（封面/下载量/评分/排行）。
  - `scrapeAll(id)` —— `Future.wait` 并发合并两者。
- 配套：`DioClient`（带重试）、`HvdbScraper`、`ScraperUtils`（RJ 编码、name→UUID）、`ScraperController`、`ScraperStorage`、`ScraperDio`。

#### `theme/` — 主题系统

- **`AppTheme`**：`light(seed, fontPreset)` / `dark(...)` 构建完整 `ThemeData`（Material 3），含 colorScheme、textTheme、cupertinoOverride、bottomSheet、divider、appBar、navigationRail/Bar、card 等全局样式，并注入 `WoltModalSheetThemeData` 扩展。
- **`AppColors`**：浅/深色背景、卡片、文本、分隔线、阴影常量。
- **`AppFontPreset`**：字体预设枚举（NotoSansSc 等），提供 `applyToTextTheme` 与 storageKey 序列化。
- **`ThemeNotifier`**（Riverpod `Notifier<ThemeState>`）：持久化 mode/seed/recent/fontPreset 到 Hive，提供 `setMode` / `toggleLightDark` / `setSeedColor` / `setFontPreset`。
- 派生 Provider：`platformBrightnessProvider`、`explicitDarkModeProvider`。

#### `common/` — 通用类型

- `GlobalException implements Exception`：统一异常（message / originalError / stackTrace / code / context）。
- `errors.dart`：`mapToGlobalException(e)` 把 Dio/原生异常映射为 `GlobalException`。
- `pagination.dart` / `page_result.dart`：分页与结果包装。

#### `routes/` — 路由

- **`goRouterProvider`**：`StatefulShellRoute.indexedStack` 包 4 个主分支（home / category / localMedia / user），home 分支含子路由 `hotAndRecommend` 与 `detail`；外层 `login` / `settings`（含 about/permission/log/theme/cache/globalFilter 子路由）/ `imageView` / `search`。统一观察者 `KikoenaiDialog.observer`。
- **`AppRoutes`**：所有路径常量 + `toRelative` 辅助 + `mainPages` 列表。

### 5.4 表现层（`lib/features/`）

每个特性内部统一为 `data/`（model + service/repository）与 `presentation/`（page + provider + widget + state）。

| 特性            | 职责                                                                                       | 关键 Provider                                  |
| ------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------- |
| **album**     | 作品列表（首页）、作品详情、分类作品页；`WorkRepository` 对接 `/search`、`/recommender/popular`、`/recommender/recommend-for-user`、`/tracks/{id}`、`/work/{id}`、`/review` | `workRepositoryProvider`、`workProvider`、`audioFileProvider`、`fileManageProvider` |
| **player**    | 播放器 UI（音频/视频/歌词/控制/队列/睡眠定时）与状态编排                                                          | `playerControllerProvider`（核心 `PlayerController`）、`playerLyricsProvider`、`playerSleepTimeProvider`、`playerLyricsMatchProvider` |
| **local_media** | 本地媒体库扫描面板、路径选择、重命名、解析进度、使用引导                                                             | `fileScannerNotifier`、`filePathNotifier`    |
| **auth**      | 登录/注册（`AuthRepository` 对接 `/auth/me`、`/auth/register`）                                    | `authProvider`、`authRepositoryProvider`     |
| **category**  | 分类标签页与筛选头                                                                                | `categoryDataProvider`、`categoryOptionProvider`、`categoryKeepAlive` |
| **history**   | 收听历史列表与恢复播放                                                                              | `historyControllerProvider`                 |
| **marked**    | 在线标记（想看/在看/看过/搁置/抛弃）、1–10 分评分、评论                                                          | `reviewProvider`、`reviewRepository`         |
| **playlist**  | 播放列表 CRUD 与展示                                                                            | `playlistProvider`、`playlistRepository`     |
| **search**    | 关键字搜索                                                                                    | `searchProvider`                            |
| **settings**  | 设置主页 + 主题/权限/缓存/全局筛选子页                                                                   | `settingProvider`、`defaultMarkTargetPlaylistProvider` |
| **overly-lyrics** | 桌面悬浮歌词面板与同步服务                                                                            | `lyricsControllerProvider`（`overlayMain` 入口消费） |
| **download**  | 下载任务页                                                                                    | `downloadProvider`                          |
| **user**      | 用户中心、文件预览、导入状态                                                                           | `filePreviewProvider`                       |
| **about** / **log** | 关于页 / 日志查看页                                                                              | `aboutProvider`                             |

---

## 6. 关键类与函数说明

### 6.1 入口与配置

| 类/函数                                  | 位置                                              | 说明                                              |
| ------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `main()`                              | [main.dart](file:///f:/flutterwork/flutter-framework/lib/main.dart) | 冷启动主入口，串联所有初始化                                 |
| `overlayMain()`                       | 同上                                              | 悬浮窗独立 isolate 入口（`@pragma("vm:entry-point")`）   |
| `MyApp`                               | [app.dart](file:///f:/flutterwork/flutter-framework/lib/app/app.dart) | 根 Widget，组装主题与路由                               |
| `EnvironmentConfig.selectBestServer()` | [environment_config.dart](file:///f:/flutterwork/flutter-framework/lib/config/environment_config.dart) | 服务器优选：2.5s 缓存校验 → 5s 并发探测 → 默认兜底                |
| `ServerSettingsNotifier`              | 同上                                              | 用户手动切换服务器的 Riverpod Notifier                    |
| `VersionConfig`                       | [app_version_config.dart](file:///f:/flutterwork/flutter-framework/lib/config/app_version_config.dart) | 版本/应用名/升级地址常量                                  |

### 6.2 核心服务

| 类/函数                                  | 位置                                              | 关键方法/说明                                         |
| ------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `AppStorage`                          | [hive_storage.dart](file:///f:/flutterwork/flutter-framework/lib/core/storage/hive_storage.dart) | `init()` 注册 17 个 Adapter 并打开 9 个 Box；`_openBox` 损坏自愈；`clearBox`/`getBoxSize`/`backupBox` |
| `StorageKeys`                         | [hive_key.dart](file:///f:/flutterwork/flutter-framework/lib/core/storage/hive_key.dart) | 所有 Hive Key 常量集中定义                             |
| `ApiClient`                           | [api_client.dart](file:///f:/flutterwork/flutter-framework/lib/core/utils/network/api_client.dart) | 单例 Dio 封装；`get/post/put/delete/getBytes`；`checkHealth`；拦截器注入 token/Referer；401 处理 |
| `AudioServiceSingleton`               | [audio_service_ctrl.dart](file:///f:/flutterwork/flutter-framework/lib/core/service/audio/audio_service_ctrl.dart) | `init()` 构造 `MyAudioHandler` 并配置通知渠道            |
| `MyAudioHandler`                      | 同上                                              | 桥接 `audio_service` 与 `media_kit`；队列/播放/暂停/跳转/音量/循环/随机；`customAction` 支持视频解码切换与队列重排 |
| `PlayerService`                       | [player_service.dart](file:///f:/flutterwork/flutter-framework/lib/core/service/player/player_service.dart) | 单例持有 `Player` 与懒加载 `VideoController`；`toggleVideoDecoding`；`dispose` |
| `FileScannerService`                  | [file_scanner_service.dart](file:///f:/flutterwork/flutter-framework/lib/core/service/file/file_scanner_service.dart) | `startScan(ScanTarget)` 缓存+静默同步；`result` 流广播结果  |
| `DownloadService`                     | [download_service.dart](file:///f:/flutterwork/flutter-framework/lib/core/service/download/download_service.dart) | 单例；`enqueueBatch` 递归建任务；`pause/resume/cancel`；`progressStream`/`statusStream`；脏记录自清理 |
| `CacheService`                        | [cache_service.dart](file:///f:/flutterwork/flutter-framework/lib/core/service/cache/cache_service.dart) | 单例门面；host/UUID/auth/搜索历史/播放器状态/扫描路径/带过期选项缓存     |
| `DlSiteScraper`                       | [scraper.dart](file:///f:/flutterwork/flutter-framework/lib/core/utils/scraper/scraper.dart) | `scrapeStatic`/`scrapeDynamic`/`scrapeAll` 抓取 DLSite 元数据 |

### 6.3 主题与路由

| 类/函数                | 位置                                              | 说明                                              |
| ------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `AppTheme`          | [app_theme.dart](file:///f:/flutterwork/flutter-framework/lib/core/theme/app_theme.dart) | `light(seed, fontPreset)` / `dark(...)` 全局 ThemeData |
| `ThemeNotifier`     | [theme_view_model.dart](file:///f:/flutterwork/flutter-framework/lib/core/theme/theme_view_model.dart) | 持久化主题状态；`setMode`/`toggleLightDark`/`setSeedColor`/`setFontPreset` |
| `goRouterProvider`  | [app_router.dart](file:///f:/flutterwork/flutter-framework/lib/core/routes/app_router.dart) | `StatefulShellRoute.indexedStack` + 全部路由声明       |
| `AppRoutes`         | [app_routes.dart](file:///f:/flutterwork/flutter-framework/lib/core/routes/app_routes.dart) | 路径常量 + `toRelative` + `mainPages`               |

### 6.4 核心模型

| 类                                    | 位置                                              | 说明                                              |
| ------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `Work`                                | [work.dart](file:///f:/flutterwork/flutter-framework/lib/features/album/data/model/work.dart) | 作品主模型（`@JsonSerializable`），含 id/title/circle/tags/vas/rank/cover/progress 等；`copyWith` + `heroTag` |
| `FileNode`                            | [file_node.dart](file:///f:/flutterwork/flutter-framework/lib/core/model/file_node.dart) | `@freezed` + `@HiveType`；文件树节点；`NodeSource`/`NodeType`/`NodeStatus` 枚举；`NodeFolder` 路径工具（normalize/dirName/baseName/joinPath，支持 URI） |
| `AppPlayerState`                      | lib/features/player/data/model/player_state.dart | 播放器聚合状态（session/playing/loading/progressBar/volume/repeat/shuffle/videoParams/...） |
| `PlaybackSession` / `PlaybackItem`    | lib/features/player/data/model/playback_session.dart | 播放会话与队列项（可与 `MediaItem` 互转）                     |
| `HistoryEntry`                        | lib/features/history/data/model/history_entry.dart | 收听历史条目（session + lastItemId + lastProgressMs + lastPlayTime） |
| `AuthResponse`                        | lib/features/auth/data/model/auth_response.dart   | 登录响应（含 token / user）                            |
| `GlobalException`                     | [global_exception.dart](file:///f:/flutterwork/flutter-framework/lib/core/common/global_exception.dart) | 统一异常类型（message/originalError/stackTrace/code/context） |

### 6.5 核心 Provider/Notifier

| Provider                              | 位置                                              | 说明                                              |
| ------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| `playerControllerProvider`            | [player_controller_provider.dart](file:///f:/flutterwork/flutter-framework/lib/features/player/presentation/provider/player_controller_provider.dart) | `PlayerController extends Notifier<AppPlayerState>`：监听 audio handler 流 → 更新 state；`_loadPlayerState` 从历史恢复；`handleFileTap` 处理文件点击播放；`restoreHistory` 恢复历史会话；`cyclePlayMode` 循环切换播放模式；通过 `flutter_overlay_window` 消息通道与悬浮窗双向通信 |
| `themeNotifierProvider`               | theme_view_model.dart                           | 见上                                              |
| `goRouterProvider`                    | app_router.dart                                 | 见上                                              |
| `apiClientProvider`                   | api_client.dart                                 | 暴露 `ApiClient.instance`                         |
| `workRepositoryProvider`              | [work_repository.dart](file:///f:/flutterwork/flutter-framework/lib/features/album/data/service/work_repository.dart) | `WorkRepositoryImpl` 对接作品相关 API                  |
| `authRepositoryProvider`              | [auth_repository.dart](file:///f:/flutterwork/flutter-framework/lib/features/auth/data/service/auth_repository.dart) | `AuthRepositoryImpl` 对接登录/注册                    |
| `serverSettingsProvider`              | environment_config.dart                         | 服务器切换                                           |
| `mainScaffoldProvider`                | lib/core/widgets/layout/provider/main_scaffold_provider.dart | 主脚手架状态（播放器展开/全屏）                                |
| `lyricsControllerProvider`            | lib/features/overly-lyrics/presentation/provider/overly_lyrics_provider.dart | 桌面悬浮歌词控制                                        |

### 6.6 通用 Widget

| Widget               | 位置                                              | 说明                            |
| -------------------- | ----------------------------------------------- | ----------------------------- |
| `MainScaffold`       | [app_main_scaffold.dart](file:///f:/flutterwork/flutter-framework/lib/core/widgets/layout/app_main_scaffold.dart) | 主脚手架：mobile 用底部导航 + `PlayerSheetPanel`（SlidingUp）；desktop 用 `AdaptiveNavigationRail` + AppBar；返回键优先级拦截播放器收起 |
| `PlayerSheetPanel`   | lib/core/widgets/slider/player_sheet_panel.dart | 上滑展开的播放器面板                    |
| `KikoenaiDialog`     | lib/core/widgets/common/kikoenai_dialog.dart    | 全局对话框 + 路由观察者                 |
| `KikoenaiToast`      | lib/core/widgets/layout/app_toast.dart          | 统一 Toast（success/error + action） |
| `ExtendedImagePreviewPage` | lib/core/widgets/image_box/image_view.dart | 图片预览页                         |
| `WorkCard` / `WorkGalleryCard` / `WorkSingleColCard` | lib/core/widgets/card/ | 作品卡片多种形态                      |
| `FilterWidget` / `FilterBottomPanel` | lib/core/widgets/filter/ | 筛选面板                          |
| `LottieLoading`      | lib/core/widgets/loading/lottie_loading.dart    | Lottie 加载动画                   |

---

## 7. 数据流与状态管理

### 7.1 启动数据流

```
main()
  → AppStorage.init()           [Hive: 9 Box 全部就绪]
  → AudioServiceSingleton.init() [MyAudioHandler 挂载 media_kit Player]
  → ProxyService.init()          [系统代理注入 Dio]
  → DownloadService.init()       [下载目录 + FileDownloader]
  → EnvironmentConfig.selectBestServer()  [并发探测 → 选最优 → 更新 ApiClient.baseUrl + 持久化]
  → setupDesktopWindow()         [桌面窗口尺寸/标题栏]
  → LocalMediaSyncScheduler.runStartupCheck()  [unawaited 静默同步本地媒体]
  → runApp(ProviderScope(MyApp))
        → themeNotifierProvider  [读 Hive 恢复主题]
        → goRouterProvider       [StatefulShellRoute 渲染 MainScaffold]
        → defaultMarkTargetPlaylistProvider.fetchAndCacheDefault()
```

### 7.2 播放数据流（核心）

```
用户点击文件 (FileNode)
  → PlayerController.handleFileTap(node, currentNodes, work, source)
    → 把同层 audio/video FileNode 转 PlaybackItem → MediaItem 列表
    → MyAudioHandler.loadPlaylist(mediaList, initialIndex, initialPosition, autoPlay)
      → _playIndex(index) → media_kit Player.open(Media, play)
      → playbackState / mediaItem / queue 流更新

  [MyAudioHandler 内部流订阅]
  player.stream.playing/duration/position/buffering/completed
    → playbackState.add(...)  [audio_service 统一状态总线]

  [PlayerController._listen()]
  _handler.playbackState.listen → 更新 state.progressBarState / loading
  _handler.playbackState.map(playing).distinct() → state.playing + 上报播放状态
  _handler.mediaItem.listen → state.session 更新 + skipInfo 重算
  _handler.queue.listen → session 重建
  MyAudioHandler.volumeStream → state.volume + _saveState()

  [定时持久化]
  Timer.periodic(1s) → 若 playing 则 _saveCurrentHistory()
    → HistoryController.upsert(HistoryEntry)

  [悬浮窗 isolate]
  flutter_overlay_window BasicMessageChannel ↔ 悬浮窗双向指令
    (play/pause/next/previous/closeOverlay/toggleLock/color/savePosition/updateFontSize)
```

### 7.3 本地媒体扫描数据流

```
ScannerPage → FileScannerNotifier
  → FileScannerService.startScan(ScanTarget)
    → _initAndLoadCache (从 FileScannerStorage 读扁平 FileNode)
    → _shouldSilentSync? (autoSync + 阈值小时 + lastScannedAt)
    → FileScanSyncEngine.syncTarget(target, inMemoryNodes)
    → StreamController 广播 FileScannerResult(phase)
  → FileScannerNotifier 监听 result → 更新 UI state
```

### 7.4 网络请求统一管线

```
UI/Repository
  → ApiClient.get/post/put/delete (泛型)
    → _request<T> try/catch
      → Dio 实际请求（拦截器注入 token/Referer/Origin）
      → onError: 401 → KikoenaiToast.error + 跳 login
    → catch → mapToGlobalException → throw GlobalException
```

### 7.5 状态管理约定

- **Riverpod 3.x**：`NotifierProvider` / `Provider` 为主，`Notifier<S>` 持有不可变 state（配合 `copyWith`）。
- **本地优先**：所有需持久化的状态先写 Hive（`CacheService` / `AppStorage.settingsBox`），再更新 state；冷启动由各 Notifier 的 `build()` 从 Hive 读回。
- **解耦**：Feature 之间不直接互引 Provider，必要时通过 `core/service` 单例或 `ref.read` 横向调用（如 `PlayerController` 调 `historyControllerProvider`、`mainScaffoldProvider`）。

---

## 8. 模块依赖关系

### 8.1 分层依赖方向（自上而下）

```
features/* ──► core/service/* ──► core/storage, core/utils/*
     │              │                    │
     └──────────────┴──► config/* ───────┘
                               │
                               ▼
                          平台层 (media_kit / audio_service / hive / dio ...)
```

> 规则：`features` 可依赖 `core` 与 `config`；`core` 不反向依赖 `features`（少数 Adapter/Storage 因需注册模型而 import feature model，属受控例外）；`features` 之间尽量通过 `core/service` 单例或 Riverpod 横向解耦。

### 8.2 关键依赖链

- **播放器**：`features/player` → `PlayerController` → `AudioServiceSingleton`/`MyAudioHandler` → `PlayerService` → `media_kit.Player` + `audio_service`；同时 → `historyControllerProvider`、`CacheService`、`AppStorage`、`mainScaffoldProvider`、`lyricsControllerProvider`。
- **作品**：`features/album` → `WorkRepository` → `ApiClient` → `Dio` + `EnvironmentConfig` + `CacheService`（token）。
- **本地媒体**：`features/local_media` → `FileScannerService` → `FileScanSyncEngine` + `FileScannerStorage` → `AppStorage.scannerBox` + `FileWatchService`。
- **下载**：`features/download` → `DownloadService` → `background_downloader` + `AppStorage.settingsBox`。
- **认证**：`features/auth` → `AuthRepository` → `ApiClient` + `CacheService`（UUID/会话）。
- **主题**：任意 Widget → `themeNotifierProvider`/`explicitDarkModeProvider` → `AppStorage.settingsBox`；`MyApp` → `AppTheme` → `AppColors`/`AppFontPreset`。
- **悬浮歌词**：`overlayMain` → `LyricsOverlayContent` → `lyricsControllerProvider` ↔（插件消息通道）↔ `PlayerController._listenToOverlayCommands`。

### 8.3 外部服务依赖

- **后端 API**：`api.asmr-200.com`（及镜像）—— 作品搜索/详情/轨道/推荐/标记/认证。
- **DLSite / HVDB**：元数据爬取补全（`DlSiteScraper`）。
- **GitHub Releases**：在线升级检查（`VersionConfig.latestApp`）。

---

## 9. 项目运行方式

### 9.1 环境要求

- Flutter 3.x（Dart SDK `3.11.5`，见 [pubspec.yaml](file:///f:/flutterwork/flutter-framework/pubspec.yaml)）
- Android：NDK `27.3.13750724`，`compileSdk`/`minSdk`/`targetSdk` 跟随 Flutter 默认（见 [android/app/build.gradle.kts](file:///f:/flutterwork/flutter-framework/android/app/build.gradle.kts)）
- 桌面端：Windows 需 CMake + Visual Studio；macOS 需 Xcode + CocoaPods
- iOS：CocoaPods（见 [ios/Podfile](file:///f:/flutterwork/flutter-framework/ios/Podfile)）

### 9.2 安装与代码生成

```sh
# 1. 安装依赖
flutter pub get

# 2. 运行代码生成器（freezed / json_serializable / hive_ce_generator）
flutter pub run build_runner build --delete-conflicting-outputs
```

> 修改任何 `@freezed` / `@JsonSerializable` / `@HiveType` 模型后，需重新执行 build_runner。

### 9.3 运行

```sh
# 默认（debug）
flutter run

# 指定平台
flutter run -d windows
flutter run -d macos
flutter run -d chrome      # Web
flutter run -d <device-id> # Android / iOS
```

### 9.4 构建产物

```sh
flutter build apk --release      # Android
flutter build appbundle --release
flutter build ios --release
flutter build windows --release
flutter build macos --release
flutter build web --release
```

Android release 签名读取项目根 `key.properties`（见 `signingConfigs.release`），缺失时回退空配置。

### 9.5 测试

```sh
flutter test
```

现有测试见 [test/](file:///f:/flutterwork/flutter-framework/test)：`file_encoding_helper_test.dart`、`scraper_test.dart`。

### 9.6 静态分析

```sh
flutter analyze
```

规则基于 `flutter_lints`（见 [analysis_options.yaml](file:///f:/flutterwork/flutter-framework/analysis_options.yaml)），并启用 `riverpod_lint`。

### 9.7 分发打包

仓库提供 [distribute_options.yaml](file:///f:/flutterwork/flutter-framework/distribute_options.yaml)，可配合 `fastlane` / `flutter_distributor` 之类的工具进行多渠道打包；`fast/` 目录内置 mpv / ANGLE / 各架构 jar 等原生依赖。

---

## 10. 平台与原生配置

### 10.1 Android

- **包名**：`com.karson.kikoenai`（[MainActivity.kt](file:///f:/flutterwork/flutter-framework/android/app/src/main/kotlin/com/karson/kikoenai/MainActivity.kt)）
- **通知渠道**：`com.karson.kikoenai.audio`（音频播放通知）
- **签名**：`key.properties` + `signingConfigs.release`
- **音频输出模式**：支持 `audiotrack` / `aaudio` / `opensles`（见 `AppConstants.validAoModes`），默认 `audiotrack`
- **原生库**：`fast/` 提供 `default-*.jar`（arm64-v8a/armeabi-v7a/x86/x86_64）与 mpv dev 包

### 10.2 iOS / macOS

- [ios/Podfile](file:///f:/flutterwork/flutter-framework/ios/Podfile) / [macos/Podfile](file:///f:/flutterwork/flutter-framework/macos/Podfile)（CocoaPods）
- [ios/Runner/Info.plist](file:///f:/flutterwork/flutter-framework/ios/Runner/Info.plist) / [macos/Runner/Info.plist](file:///f:/flutterwork/flutter-framework/macos/Runner/Info.plist)
- 下载路径策略：iOS 用 `ApplicationDocumentsDirectory`，其他平台用 `DownloadsDirectory`

### 10.3 Windows

- [windows/CMakeLists.txt](file:///f:/flutterwork/flutter-framework/windows/CMakeLists.txt) + `windows/runner/`
- 窗口管理：`window_manager` + `setupDesktopWindow()`（[window_init_desktop.dart](file:///f:/flutterwork/flutter-framework/lib/core/utils/window/window_init_desktop.dart)）
- 视频渲染依赖 ANGLE（`fast/ANGLE.7z`）

### 10.4 Web

- [web/index.html](file:///f:/flutterwork/flutter-framework/web/index.html) + `manifest.json` + PWA 图标
- 注意：`media_kit` / `audio_service` / 悬浮窗等原生能力在 Web 上受限

### 10.5 悬浮窗入口

`overlayMain()`（`@pragma("vm:entry-point")`）由 `flutter_overlay_window` 在 Android 端拉起独立 isolate，并通过插件内部的 `BasicMessageChannel` 与主 App 双向通信；业务层不再管理 `ReceivePort`、`SendPort` 或命名端口。

---

## 附录：核心常量速查

| 常量                        | 值/说明                                                       |
| ------------------------- | ----------------------------------------------------------- |
| `AppConstants.kPadding`   | `16.0`                                                      |
| `AppConstants.kRadius`    | `12.0`                                                      |
| `AppConstants.kMiniPlayerHeight` | `75`                                                 |
| `AppConstants.kAppBottomNavHeight` | `68`                                                |
| `AppConstants.kMobileBreakpoint` | `600.0`                                              |
| `AppConstants.apiBaseUrl` | `${EnvironmentConfig.baseUrl}/api`                          |
| `EnvironmentConfig._candidates` | `api.asmr-200.com` / `api.asmr.one` / `api.asmr-100.com` / `api.asmr-300.com` |
| `VersionConfig.version`   | `1.0.4`                                                     |
| `VersionConfig.appName`   | `Kikoenai`                                                  |
| `StorageKeys.playerLastState` | `last_state`                                            |
| `StorageKeys.currentUser` | `current_user`                                              |
| `StorageKeys.searchHistory` | `search_history`（上限 20）                                    |
| `StorageKeys.localMediaAutoSyncThresholdHours` | 默认 24（clamp 1–168）                          |

---

> 本 Wiki 基于源码静态分析生成，若代码结构演进请同步更新对应章节。
