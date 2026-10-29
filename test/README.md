# 测试目录与源码对应表

## 归档规则

- 每个包的 `test/` 镜像该包 `lib/` 中被测代码的目录；测试文件保留原名称。
- 一个源码文件可以对应多个场景测试。跨模块测试按主要验证对象归档，不拆分或删减用例。
- `test/fixtures/` 保存共享测试数据；代理证书路径保持不变。
- `integration_test/` 保留设备集成测试入口，`tool/test_player_proxy.sh` 继续使用原路径。
- 各子包保留独立测试目录；根目录的 `flutter test` 不会递归执行子包测试。
- 下表列出每个测试的主要源码入口。测试中引用的其他模块仍属于该测试的覆盖范围。

## 运行方式

在项目根目录使用项目绑定的 Flutter SDK：

```bash
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter test test/features/cloud_drive/
.fvm/flutter_sdk/bin/flutter test test/core/utils/log/kikoenai_log_test.dart
.fvm/flutter_sdk/bin/flutter test --coverage
```

子包在各自目录执行测试。例如：

```bash
cd kikoenai_core
../.fvm/flutter_sdk/bin/flutter test
```

播放器代理集成测试使用 `tool/test_player_proxy.sh`，需可用的目标设备与代理测试环境。覆盖率输出位于运行所在包的 `coverage/lcov.info`。

`kikoenai_sites` 中的 `asmr_one_dump_test.dart` 与 `asmr_gay_request_test.dart` 会访问真实站点，并受网络和代理配置影响。`package/webdav_client` 的测试包含远端目录与文件操作，需要有效的测试服务配置。

## 对应清单

共 94 个 Dart 测试文件。本清单说明文件归属，不代表所有源码均有测试，也不代表测试已全部通过。

### 主应用：core（32 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [test/core/routes/main_navigation_test.dart](../test/core/routes/main_navigation_test.dart) | [lib/core/routes/app_router.dart](../lib/core/routes/app_router.dart) |
| [test/core/service/audio/audio_service_overlay_controls_test.dart](../test/core/service/audio/audio_service_overlay_controls_test.dart) | [lib/core/service/audio/audio_service.dart](../lib/core/service/audio/audio_service.dart) |
| [test/core/service/download/download_proxy_sync_test.dart](../test/core/service/download/download_proxy_sync_test.dart) | [lib/core/service/download/download_proxy_sync.dart](../lib/core/service/download/download_proxy_sync.dart) |
| [test/core/service/file/audio_folder_preference_logic_test.dart](../test/core/service/file/audio_folder_preference_logic_test.dart) | [lib/core/service/file/audio_folder_preference.dart](../lib/core/service/file/audio_folder_preference.dart) |
| [test/core/service/file/file_node_library_index_source_test.dart](../test/core/service/file/file_node_library_index_source_test.dart) | [lib/core/service/file/file_node_library_index.dart](../lib/core/service/file/file_node_library_index.dart) |
| [test/core/service/file/work_association_index_test.dart](../test/core/service/file/work_association_index_test.dart) | [lib/core/service/file/work_association_index.dart](../lib/core/service/file/work_association_index.dart) |
| [test/core/service/lyrics/player_lyrics_style_test.dart](../test/core/service/lyrics/player_lyrics_style_test.dart) | [lib/core/service/lyrics/lyrics_parse_service.dart](../lib/core/service/lyrics/lyrics_parse_service.dart) |
| [test/core/service/player/media_http_headers_registry_test.dart](../test/core/service/player/media_http_headers_registry_test.dart) | [lib/core/service/player/media_http_headers_registry.dart](../lib/core/service/player/media_http_headers_registry.dart) |
| [test/core/service/proxy/proxy_routing_test.dart](../test/core/service/proxy/proxy_routing_test.dart) | [lib/core/service/proxy/auto_proxy_service.dart](../lib/core/service/proxy/auto_proxy_service.dart) |
| [test/core/service/proxy/proxy_service_test.dart](../test/core/service/proxy/proxy_service_test.dart) | [lib/core/service/proxy/auto_proxy_service.dart](../lib/core/service/proxy/auto_proxy_service.dart) |
| [test/core/service/proxy/proxy_settings_test.dart](../test/core/service/proxy/proxy_settings_test.dart) | [lib/core/service/proxy/proxy_settings.dart](../lib/core/service/proxy/proxy_settings.dart) |
| [test/core/service/proxy/system_proxy_config_test.dart](../test/core/service/proxy/system_proxy_config_test.dart) | [lib/core/service/proxy/system_proxy_config.dart](../lib/core/service/proxy/system_proxy_config.dart) |
| [test/core/service/site/server_info_cache_test.dart](../test/core/service/site/server_info_cache_test.dart) | [lib/core/service/site/site_api_provider.dart](../lib/core/service/site/site_api_provider.dart) |
| [test/core/service/site/site_api_provider_test.dart](../test/core/service/site/site_api_provider_test.dart) | [lib/core/service/site/site_api_provider.dart](../lib/core/service/site/site_api_provider.dart) |
| [test/core/theme/app_layout_tokens_test.dart](../test/core/theme/app_layout_tokens_test.dart) | [lib/core/theme/app_layout_tokens.dart](../lib/core/theme/app_layout_tokens.dart) |
| [test/core/utils/data/file_encoding_helper_test.dart](../test/core/utils/data/file_encoding_helper_test.dart) | [lib/core/utils/data/charset_cover.dart](../lib/core/utils/data/charset_cover.dart) |
| [test/core/utils/log/kikoenai_log_test.dart](../test/core/utils/log/kikoenai_log_test.dart) | [lib/core/utils/log/kikoenai_log.dart](../lib/core/utils/log/kikoenai_log.dart) |
| [test/core/utils/scraper/scraper_http_client_test.dart](../test/core/utils/scraper/scraper_http_client_test.dart) | [lib/core/utils/scraper/scraper_http_client.dart](../lib/core/utils/scraper/scraper_http_client.dart) |
| [test/core/utils/scraper/scraper_queue_controller_test.dart](../test/core/utils/scraper/scraper_queue_controller_test.dart) | [lib/core/utils/scraper/scraper_controller.dart](../lib/core/utils/scraper/scraper_controller.dart) |
| [test/core/utils/scraper/scraper_test.dart](../test/core/utils/scraper/scraper_test.dart) | [lib/core/utils/scraper/dlsite_scraper.dart](../lib/core/utils/scraper/dlsite_scraper.dart) |
| [test/core/utils/scraper/scraper_utils_test.dart](../test/core/utils/scraper/scraper_utils_test.dart) | [lib/core/utils/scraper/scraper_utils.dart](../lib/core/utils/scraper/scraper_utils.dart) |
| [test/core/utils/window/display_util_orientation_test.dart](../test/core/utils/window/display_util_orientation_test.dart) | [lib/core/utils/window/display_util.dart](../lib/core/utils/window/display_util.dart) |
| [test/core/widgets/bread_crumb_bar/breadcrumb_bar_test.dart](../test/core/widgets/bread_crumb_bar/breadcrumb_bar_test.dart) | [lib/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart](../lib/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart) |
| [test/core/widgets/card/card_image_loading_test.dart](../test/core/widgets/card/card_image_loading_test.dart) | [lib/core/widgets/card/work_card.dart](../lib/core/widgets/card/work_card.dart) |
| [test/core/widgets/common/guest_placeholder_view_test.dart](../test/core/widgets/common/guest_placeholder_view_test.dart) | [lib/core/widgets/common/guest_placeholder_view.dart](../lib/core/widgets/common/guest_placeholder_view.dart) |
| [test/core/widgets/common/toolbar_search_field_test.dart](../test/core/widgets/common/toolbar_search_field_test.dart) | [lib/core/widgets/common/toolbar_search_field.dart](../lib/core/widgets/common/toolbar_search_field.dart) |
| [test/core/widgets/layout/app_system_ui_test.dart](../test/core/widgets/layout/app_system_ui_test.dart) | [lib/core/widgets/layout/app_system_ui.dart](../lib/core/widgets/layout/app_system_ui.dart) |
| [test/core/widgets/layout/responsive_main_scaffold_test.dart](../test/core/widgets/layout/responsive_main_scaffold_test.dart) | [lib/core/widgets/layout/app_main_scaffold.dart](../lib/core/widgets/layout/app_main_scaffold.dart) |
| [test/core/widgets/layout/scroll_aware_toolbar_layout_test.dart](../test/core/widgets/layout/scroll_aware_toolbar_layout_test.dart) | [lib/core/widgets/layout/scroll_aware_toolbar_layout.dart](../lib/core/widgets/layout/scroll_aware_toolbar_layout.dart) |
| [test/core/widgets/pagination/kiko_paging_state_test.dart](../test/core/widgets/pagination/kiko_paging_state_test.dart) | [lib/core/widgets/pagination/kiko_paging_state.dart](../lib/core/widgets/pagination/kiko_paging_state.dart) |
| [test/core/widgets/scroll/non_bouncing_refresh_scroll_physics_test.dart](../test/core/widgets/scroll/non_bouncing_refresh_scroll_physics_test.dart) | [lib/core/widgets/scroll/my_scroll_behavior.dart](../lib/core/widgets/scroll/my_scroll_behavior.dart) |
| [test/core/widgets/slider/player_sheet_panel_test.dart](../test/core/widgets/slider/player_sheet_panel_test.dart) | [lib/core/widgets/slider/player_sheet_panel.dart](../lib/core/widgets/slider/player_sheet_panel.dart) |

### 主应用：features（41 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [test/features/album/page/album_media_sources_test.dart](../test/features/album/page/album_media_sources_test.dart) | [lib/features/album/page/album_detail.dart](../lib/features/album/page/album_detail.dart) |
| [test/features/album/widget/alist_private_playback_test.dart](../test/features/album/widget/alist_private_playback_test.dart) | [lib/features/album/widget/file_box.dart](../lib/features/album/widget/file_box.dart) |
| [test/features/album/widget/folder_parse_status_test.dart](../test/features/album/widget/folder_parse_status_test.dart) | [lib/features/album/widget/file_box.dart](../lib/features/album/widget/file_box.dart) |
| [test/features/auth/page/auth_page_test.dart](../test/features/auth/page/auth_page_test.dart) | [lib/features/auth/page/auth_page.dart](../lib/features/auth/page/auth_page.dart) |
| [test/features/auth/provider/auth_provider_test.dart](../test/features/auth/provider/auth_provider_test.dart) | [lib/features/auth/provider/auth_provider.dart](../lib/features/auth/provider/auth_provider.dart) |
| [test/features/cloud_drive/page/cloud_drive_batch_playback_test.dart](../test/features/cloud_drive/page/cloud_drive_batch_playback_test.dart) | [lib/features/cloud_drive/page/cloud_drive_browser_page.dart](../lib/features/cloud_drive/page/cloud_drive_browser_page.dart) |
| [test/features/cloud_drive/page/cloud_drive_in_place_navigation_test.dart](../test/features/cloud_drive/page/cloud_drive_in_place_navigation_test.dart) | [lib/features/cloud_drive/page/cloud_drive_browser_page.dart](../lib/features/cloud_drive/page/cloud_drive_browser_page.dart) |
| [test/features/cloud_drive/page/webdav_settings_page_test.dart](../test/features/cloud_drive/page/webdav_settings_page_test.dart) | [lib/features/cloud_drive/page/webdav_settings_page.dart](../lib/features/cloud_drive/page/webdav_settings_page.dart) |
| [test/features/cloud_drive/provider/cloud_drive_browser_controller_test.dart](../test/features/cloud_drive/provider/cloud_drive_browser_controller_test.dart) | [lib/features/cloud_drive/provider/cloud_drive_browser_controller.dart](../lib/features/cloud_drive/provider/cloud_drive_browser_controller.dart) |
| [test/features/cloud_drive/provider/webdav_provider_test.dart](../test/features/cloud_drive/provider/webdav_provider_test.dart) | [lib/features/cloud_drive/provider/webdav_connection_controller.dart](../lib/features/cloud_drive/provider/webdav_connection_controller.dart) |
| [test/features/cloud_drive/widget/alist_server_form_dialog_test.dart](../test/features/cloud_drive/widget/alist_server_form_dialog_test.dart) | [lib/features/cloud_drive/widget/alist_server_form_dialog.dart](../lib/features/cloud_drive/widget/alist_server_form_dialog.dart) |
| [test/features/cloud_drive/widget/cloud_drive_breadcrumb_test.dart](../test/features/cloud_drive/widget/cloud_drive_breadcrumb_test.dart) | [lib/features/cloud_drive/widget/cloud_drive_breadcrumb.dart](../lib/features/cloud_drive/widget/cloud_drive_breadcrumb.dart) |
| [test/features/cloud_drive/widget/cloud_drive_mode_switch_test.dart](../test/features/cloud_drive/widget/cloud_drive_mode_switch_test.dart) | [lib/features/cloud_drive/widget/cloud_drive_mode_switch.dart](../lib/features/cloud_drive/widget/cloud_drive_mode_switch.dart) |
| [test/features/cloud_drive/widget/cloud_drive_scroll_aware_layout_test.dart](../test/features/cloud_drive/widget/cloud_drive_scroll_aware_layout_test.dart) | [lib/features/cloud_drive/widget/cloud_drive_scroll_aware_layout.dart](../lib/features/cloud_drive/widget/cloud_drive_scroll_aware_layout.dart) |
| [test/features/cloud_drive/widget/cloud_drive_toolbar_test.dart](../test/features/cloud_drive/widget/cloud_drive_toolbar_test.dart) | [lib/features/cloud_drive/widget/cloud_drive_toolbar.dart](../lib/features/cloud_drive/widget/cloud_drive_toolbar.dart) |
| [test/features/dl_page/media/dl_media_aggregation_test.dart](../test/features/dl_page/media/dl_media_aggregation_test.dart) | [lib/features/dl_page/media/dl_media_aggregation_controller.dart](../lib/features/dl_page/media/dl_media_aggregation_controller.dart) |
| [test/features/dl_page/media/webdav_media_index_test.dart](../test/features/dl_page/media/webdav_media_index_test.dart) | [lib/features/dl_page/media/webdav_media_index.dart](../lib/features/dl_page/media/webdav_media_index.dart) |
| [test/features/dl_page/widget/dl_library_chrome_test.dart](../test/features/dl_page/widget/dl_library_chrome_test.dart) | [lib/features/dl_page/widget/dl_library_header.dart](../lib/features/dl_page/widget/dl_library_header.dart) |
| [test/features/dl_page/widget/dl_library_layout_test.dart](../test/features/dl_page/widget/dl_library_layout_test.dart) | [lib/features/dl_page/widget/parsed_works_view.dart](../lib/features/dl_page/widget/parsed_works_view.dart) |
| [test/features/download/page/download_page_test.dart](../test/features/download/page/download_page_test.dart) | [lib/features/download/page/download_page.dart](../lib/features/download/page/download_page.dart) |
| [test/features/file_browser/provider/file_browser_edit_test.dart](../test/features/file_browser/provider/file_browser_edit_test.dart) | [lib/features/file_browser/provider/file_browser_edit_actions.dart](../lib/features/file_browser/provider/file_browser_edit_actions.dart) |
| [test/features/file_browser/widget/file_management_sheet_test.dart](../test/features/file_browser/widget/file_management_sheet_test.dart) | [lib/features/file_browser/widget/file_management_sheet.dart](../lib/features/file_browser/widget/file_management_sheet.dart) |
| [test/features/history/provider/work_progress_repository_test.dart](../test/features/history/provider/work_progress_repository_test.dart) | [lib/features/history/provider/work_progress_repository.dart](../lib/features/history/provider/work_progress_repository.dart) |
| [test/features/local_media/page/local_media_page_layout_test.dart](../test/features/local_media/page/local_media_page_layout_test.dart) | [lib/features/local_media/page/local_media_page.dart](../lib/features/local_media/page/local_media_page.dart) |
| [test/features/local_media/widget/local_media_chrome_test.dart](../test/features/local_media/widget/local_media_chrome_test.dart) | [lib/features/local_media/widget/local_media_header.dart](../lib/features/local_media/widget/local_media_header.dart) |
| [test/features/log/page/logger_view_test.dart](../test/features/log/page/logger_view_test.dart) | [lib/features/log/page/logger_view.dart](../lib/features/log/page/logger_view.dart) |
| [test/features/overly-lyrics/page/overly_lyrics_panel_test.dart](../test/features/overly-lyrics/page/overly_lyrics_panel_test.dart) | [lib/features/overly-lyrics/page/overly_lyrics_panel.dart](../lib/features/overly-lyrics/page/overly_lyrics_panel.dart) |
| [test/features/overly-lyrics/provider/overly_lyrics_manager_test.dart](../test/features/overly-lyrics/provider/overly_lyrics_manager_test.dart) | [lib/features/overly-lyrics/provider/overly_lyrics_manager.dart](../lib/features/overly-lyrics/provider/overly_lyrics_manager.dart) |
| [test/features/player/page/player_view_layout_test.dart](../test/features/player/page/player_view_layout_test.dart) | [lib/features/player/page/player_view.dart](../lib/features/player/page/player_view.dart) |
| [test/features/player/provider/overlay_lyrics_font_size_persistence_test.dart](../test/features/player/provider/overlay_lyrics_font_size_persistence_test.dart) | [lib/features/player/provider/player_controller_provider.dart](../lib/features/player/provider/player_controller_provider.dart) |
| [test/features/player/provider/player_cloud_file_browser_test.dart](../test/features/player/provider/player_cloud_file_browser_test.dart) | [lib/features/player/provider/player_cloud_file_browser_controller.dart](../lib/features/player/provider/player_cloud_file_browser_controller.dart) |
| [test/features/player/provider/player_cloud_file_source_test.dart](../test/features/player/provider/player_cloud_file_source_test.dart) | [lib/features/player/provider/player_cloud_file_source_provider.dart](../lib/features/player/provider/player_cloud_file_source_provider.dart) |
| [test/features/player/widget/video/player_video_brightness_test.dart](../test/features/player/widget/video/player_video_brightness_test.dart) | [lib/features/player/widget/video/player_video_gesture_layer.dart](../lib/features/player/widget/video/player_video_gesture_layer.dart) |
| [test/features/player/widget/video/player_video_seek_gesture_test.dart](../test/features/player/widget/video/player_video_seek_gesture_test.dart) | [lib/features/player/widget/video/player_video_gesture_layer.dart](../lib/features/player/widget/video/player_video_gesture_layer.dart) |
| [test/features/player/widget/video/video_floating_overlay_test.dart](../test/features/player/widget/video/video_floating_overlay_test.dart) | [lib/features/player/widget/video/video_floating_overlay.dart](../lib/features/player/widget/video/video_floating_overlay.dart) |
| [test/features/settings/page/global_filter_page_theme_test.dart](../test/features/settings/page/global_filter_page_theme_test.dart) | [lib/features/settings/page/global_filter_page.dart](../lib/features/settings/page/global_filter_page.dart) |
| [test/features/settings/page/proxy_settings_page_test.dart](../test/features/settings/page/proxy_settings_page_test.dart) | [lib/features/settings/page/proxy_settings_page.dart](../lib/features/settings/page/proxy_settings_page.dart) |
| [test/features/settings/widget/audio_folder_preference_test.dart](../test/features/settings/widget/audio_folder_preference_test.dart) | [lib/features/settings/widget/audio_folder_preference_sheet.dart](../lib/features/settings/widget/audio_folder_preference_sheet.dart) |
| [test/features/settings/widget/self_hosted_site_form_dialog_test.dart](../test/features/settings/widget/self_hosted_site_form_dialog_test.dart) | [lib/features/settings/widget/self_hosted_site_form_dialog.dart](../lib/features/settings/widget/self_hosted_site_form_dialog.dart) |
| [test/features/site/page/site_unavailable_page_test.dart](../test/features/site/page/site_unavailable_page_test.dart) | [lib/features/site/page/site_unavailable_page.dart](../lib/features/site/page/site_unavailable_page.dart) |
| [test/features/user/page/user_download_entry_test.dart](../test/features/user/page/user_download_entry_test.dart) | [lib/features/user/page/user_page.dart](../lib/features/user/page/user_page.dart) |

### integration_test（1 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [integration_test/player_proxy_test.dart](../integration_test/player_proxy_test.dart) | [lib/core/service/player/player_service.dart](../lib/core/service/player/player_service.dart) |

### kikoenai_core/test（5 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [kikoenai_core/test/core/model/history/history_session_migration_test.dart](../kikoenai_core/test/core/model/history/history_session_migration_test.dart) | [kikoenai_core/lib/core/model/history/history_migration.dart](../kikoenai_core/lib/core/model/history/history_migration.dart) |
| [kikoenai_core/test/core/model/local_media/file_origin_test.dart](../kikoenai_core/test/core/model/local_media/file_origin_test.dart) | [kikoenai_core/lib/core/model/local_media/file_origin.dart](../kikoenai_core/lib/core/model/local_media/file_origin.dart) |
| [kikoenai_core/test/core/model/site/site_content_identity_test.dart](../kikoenai_core/test/core/model/site/site_content_identity_test.dart) | [kikoenai_core/lib/core/model/site/site_content_id.dart](../kikoenai_core/lib/core/model/site/site_content_id.dart) |
| [kikoenai_core/test/core/utils/rj_code_test.dart](../kikoenai_core/test/core/utils/rj_code_test.dart) | [kikoenai_core/lib/core/utils/rj_code.dart](../kikoenai_core/lib/core/utils/rj_code.dart) |
| [kikoenai_core/test/core/utils/version_comparison_test.dart](../kikoenai_core/test/core/utils/version_comparison_test.dart) | [kikoenai_core/lib/core/utils/other.dart](../kikoenai_core/lib/core/utils/other.dart) |

### kikoenai_sites/test（11 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [kikoenai_sites/test/api/server_info_test.dart](../kikoenai_sites/test/api/server_info_test.dart) | [kikoenai_sites/lib/api/server_info.dart](../kikoenai_sites/lib/api/server_info.dart) |
| [kikoenai_sites/test/api/site_registry_test.dart](../kikoenai_sites/test/api/site_registry_test.dart) | [kikoenai_sites/lib/api/site_registry.dart](../kikoenai_sites/lib/api/site_registry.dart) |
| [kikoenai_sites/test/network/cookie_manager_test.dart](../kikoenai_sites/test/network/cookie_manager_test.dart) | [kikoenai_sites/lib/network/cookie_manager.dart](../kikoenai_sites/lib/network/cookie_manager.dart) |
| [kikoenai_sites/test/network/exception_test.dart](../kikoenai_sites/test/network/exception_test.dart) | [kikoenai_sites/lib/network/exception.dart](../kikoenai_sites/lib/network/exception.dart) |
| [kikoenai_sites/test/network/http_client_test.dart](../kikoenai_sites/test/network/http_client_test.dart) | [kikoenai_sites/lib/network/http_client.dart](../kikoenai_sites/lib/network/http_client.dart) |
| [kikoenai_sites/test/network/interceptor_test.dart](../kikoenai_sites/test/network/interceptor_test.dart) | [kikoenai_sites/lib/network/interceptor.dart](../kikoenai_sites/lib/network/interceptor.dart) |
| [kikoenai_sites/test/network/request_config_test.dart](../kikoenai_sites/test/network/request_config_test.dart) | [kikoenai_sites/lib/network/request_config.dart](../kikoenai_sites/lib/network/request_config.dart) |
| [kikoenai_sites/test/sites/asmr_gay/asmr_gay_custom_servers_test.dart](../kikoenai_sites/test/sites/asmr_gay/asmr_gay_custom_servers_test.dart) | [kikoenai_sites/lib/sites/asmr_gay/asmr_gay_site_api.dart](../kikoenai_sites/lib/sites/asmr_gay/asmr_gay_site_api.dart) |
| [kikoenai_sites/test/sites/asmr_gay/asmr_gay_request_test.dart](../kikoenai_sites/test/sites/asmr_gay/asmr_gay_request_test.dart) | [kikoenai_sites/lib/sites/asmr_gay/asmr_gay_site_api.dart](../kikoenai_sites/lib/sites/asmr_gay/asmr_gay_site_api.dart) |
| [kikoenai_sites/test/sites/asmr_one/asmr_one_dump_test.dart](../kikoenai_sites/test/sites/asmr_one/asmr_one_dump_test.dart) | [kikoenai_sites/lib/sites/asmr_one/asmr_one_site_api.dart](../kikoenai_sites/lib/sites/asmr_one/asmr_one_site_api.dart) |
| [kikoenai_sites/test/sites/kikoeru/kikoeru_site_api_test.dart](../kikoenai_sites/test/sites/kikoeru/kikoeru_site_api_test.dart) | [kikoenai_sites/lib/sites/kikoeru/kikoeru_site_api.dart](../kikoenai_sites/lib/sites/kikoeru/kikoeru_site_api.dart) |

### package/flutter_lyric/test（2 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [package/flutter_lyric/test/core/apple_music_style_test.dart](../package/flutter_lyric/test/core/apple_music_style_test.dart) | [package/flutter_lyric/lib/core/lyric_styles.dart](../package/flutter_lyric/lib/core/lyric_styles.dart) |
| [package/flutter_lyric/test/core/lyric_parse_test.dart](../package/flutter_lyric/test/core/lyric_parse_test.dart) | [package/flutter_lyric/lib/core/lyric_parse.dart](../package/flutter_lyric/lib/core/lyric_parse.dart) |

### package/flutter_overlay_window/test（1 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [package/flutter_overlay_window/test/flutter_overlay_window_test.dart](../package/flutter_overlay_window/test/flutter_overlay_window_test.dart) | [package/flutter_overlay_window/lib/flutter_overlay_window.dart](../package/flutter_overlay_window/lib/flutter_overlay_window.dart) |

### package/webdav_client/test（1 个）

| 测试文件 | 主要源码入口 |
| --- | --- |
| [package/webdav_client/test/webdav_client_test.dart](../package/webdav_client/test/webdav_client_test.dart) | [package/webdav_client/lib/webdav_client.dart](../package/webdav_client/lib/webdav_client.dart) |
