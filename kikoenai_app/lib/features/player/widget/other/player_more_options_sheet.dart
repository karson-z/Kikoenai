import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';
import 'package:kikoenai/features/album/provider/audio_file_provider.dart';
import 'package:kikoenai/features/file_sort/provider/file_sort_provider.dart';
import 'package:kikoenai/features/player/widget/other/player_lyrics_edit.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:kikoenai/features/player/widget/lyrics/player_lyrics_mapping_sheet.dart';
import 'package:kikoenai/features/player/widget/other/player_more_widget.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../../core/service/file/file_node_library_index.dart';
import '../../../../../core/service/file/file_scanner_storage.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../../../../../core/widgets/common/manage_playlist_dialog.dart';
import '../../../../../core/widgets/layout/app_main_scaffold.dart';
import '../../../../../core/widgets/layout/app_toast.dart';
import '../../../../../core/widgets/layout/provider/main_scaffold_provider.dart';
import '../../../local_media/provider/file_path_notifier.dart';
import '../../../local_media/provider/file_scanner_notifier.dart';
import '../../../overly-lyrics/widget/overly_setting_panel.dart';
import '../../provider/player_controller_provider.dart';

/// 触发 WoltModalSheet 更多选项
void showMoreOptions(BuildContext context, WidgetRef ref, PlaybackItem? track) {
  if (track == null) return;

  WoltModalSheet.show<void>(
    context: context,
    modalTypeBuilder: (modalContext) {
      final width = MediaQuery.of(modalContext).size.width;
      return width < 500
          ? const CustomBottomType()
          : const CustomSideSheetType();
    },
    pageListBuilder: (modalContext) {
      return [_buildWoltPage(modalContext, track)];
    },
  );
}

/// 提取构建 Page 的逻辑，避免 show 方法过于臃肿
SliverWoltModalSheetPage _buildWoltPage(
  BuildContext context,
  PlaybackItem track,
) {
  return SliverWoltModalSheetPage(
    hasTopBarLayer: false,
    isTopBarLayerAlwaysVisible: false,
    hasSabGradient: false,
    mainContentSliversBuilder: (context) => [
      const SliverPadding(padding: EdgeInsets.only(top: 16)),
      SliverToBoxAdapter(
        child: BackButtonPriorityWrapper(
          zIndex: 100,
          name: 'PlayerMoreOptionsBottomSheet',
          child: Consumer(
            builder: (context, ref, child) {
              return _MoreOptionsContent(track: track);
            },
          ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
    ],
  );
}

/// 拆分出的内容组件，负责读取状态和构建菜单
class _MoreOptionsContent extends ConsumerWidget {
  final PlaybackItem track;

  const _MoreOptionsContent({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAudioOnly = ref.watch(
      playerControllerProvider.select((s) => s.isAudioOnly),
    );
    final workId = track.workId;
    final work = workId == null ? null : ScraperStorage().getWork(workId);
    final bool isVideoTrack = track.isVideo;

    final List<ListActionItem> dynamicListActions = [
      ListActionItem(
        icon: Icons.multitrack_audio_outlined,
        title: '忽略音频焦点',
        hasSwitch: true,
        initialSwitchValue: AppStorage.settingsBox.get(
          StorageKeys.ignoreAudioFocus,
          defaultValue: false,
        ),
        onSwitchChanged: (bool value) async {
          AppStorage.settingsBox.put(StorageKeys.ignoreAudioFocus, value);
        },
      ),
      ListActionItem(
        icon: Icons.play_circle_outline,
        title: '允许后台播放',
        hasSwitch: true,
        initialSwitchValue: AppStorage.settingsBox.get(
          StorageKeys.playerPlayInBackground,
          defaultValue: true,
        ),
        onSwitchChanged: (bool value) async {
          await AppStorage.settingsBox.put(
            StorageKeys.playerPlayInBackground,
            value,
          );
        },
      ),
      ListActionItem(
        icon: Icons.subtitles,
        title: '字幕匹配',
        onTap: () async {
          await LyricsMappingSheet.show();
        },
      ),
    ];

    if (isVideoTrack) {
      dynamicListActions.add(
        ListActionItem(
          icon: Icons.videocam_off_outlined,
          title: '仅音频模式',
          subtitle: '关闭视频画面以省电',
          hasSwitch: true,
          initialSwitchValue: isAudioOnly,
          onSwitchChanged: (bool value) async {
            ref
                .read(playerControllerProvider.notifier)
                .toggleAudioOnlyMode(value);
            await AudioServiceSingleton.instance.customAction(
              'toggleVideoDecoding',
              {'enable': !value},
            );
            final isFullScreen = ref.read(
              mainScaffoldProvider.select((p) => p.isFullScreen),
            );
            if (isFullScreen) {
              final controller = ref.read(mainScaffoldProvider.notifier);
              controller.setFullScreen(false);
              await DisplayUtils.exitFullScreen();
            }
          },
        ),
      );
    }

    dynamicListActions.addAll([
      if (track.isLocal && FileExtensions.isMedia(track.url))
        ListActionItem(
          icon: Icons.drive_file_move_outline,
          title: '跳转到所在文件夹',
          onTap: () => _handleContainingFolderTap(context, ref, track),
        ),
      if (!track.isLocal && workId != null)
        ListActionItem(
          icon: Icons.album_outlined,
          title: "专辑",
          subtitle: track.albumTitle,
          onTap: () => _handleAlbumTap(context, ref, track),
        ),
      ListActionItem(
        icon: Icons.person_outline_rounded,
        title: "歌手",
        subtitle: track.artist,
      ),
    ]);

    return MoreOptionsBottomSheet(
      track: track,
      quickActions: _buildQuickActions(context, track, ref, work, workId),
      listActions: dynamicListActions,
    );
  }

  List<QuickActionItem> _buildQuickActions(
    BuildContext context,
    PlaybackItem track,
    WidgetRef ref,
    Work? work,
    int? workId,
  ) {
    return [
      QuickActionItem(
        icon: Icons.favorite_border,
        label: "收藏",
        onTap: () => Navigator.pop(context),
      ),
      QuickActionItem(
        icon: Icons.lyrics_outlined,
        label: "字幕样式",
        onTap: () {
          // 跳转至字幕配置第二页
          final page = buildLyricsStylePage(context);
          WoltModalSheet.of(context).addPage(page);
          WoltModalSheet.of(context).showNext();
        },
      ),
      QuickActionItem(
        icon: Icons.folder_open_outlined,
        label: "文件管理",
        onTap: () async {
          try {
            FileNodeLibraryIndex index;
            if (track.isLocal) {
              index = await _buildLocalIndexForTrack(ref, track);
            } else {
              final contentId = track.contentId;
              if (contentId == null) {
                KikoenaiToast.warning('当前音频缺少来源站点信息');
                return;
              }
              index = await ref.read(
                trackFileNodeIndexProvider(contentId).future,
              );
            }
            if (!context.mounted) return;
            final fileTreePage = FileTreeWoltSheet.buildPage(
              context,
              index: index,
              work: work,
              isFirstPage: false,
            );
            WoltModalSheet.of(context).addPage(fileTreePage);
            WoltModalSheet.of(context).showNext();
          } catch (e) {
            if (context.mounted) KikoenaiToast.error("获取文件列表失败");
          }
        },
      ),
      QuickActionItem(
        icon: Icons.picture_in_picture_alt,
        label: "桌面字幕",
        onTap: () => _handleSubtitleConfig(context),
      ),
    ];
  }

  /// 为本地 [track] 构建索引：遍历 audio / video 扫描目标，
  /// 找到包含该文件的目录后构建 [FileNodeLibraryIndex] 并跳转到所在层级。
  ///
  /// 找不到时抛出 [StateError]，由调用方 catch 转为 Toast。
  Future<FileNodeLibraryIndex> _buildLocalIndexForTrack(
    WidgetRef ref,
    PlaybackItem track,
  ) async {
    final filePath = track.url;
    final normalizedFilePath = FileNodeLibraryIndex.normalizePath(filePath);
    final targets = ref.read(scanTargetsProvider.notifier);

    for (final mode in const [ScanMode.audio, ScanMode.video]) {
      for (final target in targets.getTargetsByMode(mode)) {
        if (!_isPathInsideRoot(normalizedFilePath, target.path)) continue;

        final cachedNodes = FileScannerStorage().getNodesByRootPath(
          mode,
          target.path,
        );
        if (cachedNodes.isEmpty) continue;

        final index = FileNodeLibraryIndex(
          flatNodes: cachedNodes,
          rootPath: target.path,
        )..applySort(ref.read(fileSortProvider));
        if (index.jumpToFilePath(normalizedFilePath)) {
          return index;
        }
      }
    }
    throw StateError('本地文件未在已扫描目录中找到：$filePath');
  }

  bool _isPathInsideRoot(String filePath, String rootPath) {
    final normalizedFilePath = FileNodeLibraryIndex.normalizePath(
      filePath,
    ).toLowerCase();
    final normalizedRootPath = FileNodeLibraryIndex.normalizePath(
      rootPath,
    ).toLowerCase();
    return normalizedFilePath == normalizedRootPath ||
        normalizedFilePath.startsWith('$normalizedRootPath/');
  }

  void _handleAlbumTap(
    BuildContext context,
    WidgetRef ref,
    PlaybackItem track,
  ) {
    Navigator.pop(context);
    final workId = track.workId;
    final work = workId == null ? null : ScraperStorage().getWork(workId);
    final panelCtrl = ref.read(panelControllerProvider);
    if (panelCtrl.isPanelOpen) panelCtrl.close();

    context.push(
      AppRoutes.detail,
      extra: {'workId': workId, if (work != null) 'work': work},
    );
  }

  Future<void> _handleContainingFolderTap(
    BuildContext context,
    WidgetRef ref,
    PlaybackItem track,
  ) async {
    final didOpen = ref
        .read(fileScannerProvider.notifier)
        .jumpToMediaFile(track.url);
    if (!didOpen) {
      KikoenaiToast.warning('无法在本地媒体库中找到该文件');
      return;
    }
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    final panelController = ref.read(panelControllerProvider);
    Navigator.pop(context);
    router.go(AppRoutes.localMedia);
    if (panelController.isPanelOpen) await panelController.close();
  }

  void _handleSubtitleConfig(BuildContext context) {
    Navigator.pop(context);
    KikoenaiDialog.showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const BackButtonPriorityWrapper(
        zIndex: 101,
        name: 'SubtitleConfigBottomSheet',
        child: SubtitleConfigBottomSheet(),
      ),
    );
  }
}
