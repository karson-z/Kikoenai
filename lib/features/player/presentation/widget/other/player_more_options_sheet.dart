import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import 'package:kikoenai/features/player/data/model/playback_session.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_lyrics_edit.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:kikoenai/features/player/presentation/widget/lyrics/player_lyrics_mapping_sheet.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_more_widget.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../../core/service/file/file_node_library_index.dart';
import '../../../../../core/service/file/file_scanner_storage.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../../../../core/utils/log/kikoenai_log.dart';
import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../../../../../core/widgets/common/manage_playlist_dialog.dart';
import '../../../../../core/widgets/layout/app_main_scaffold.dart';
import '../../../../../core/widgets/layout/app_toast.dart';
import '../../../../../core/widgets/layout/provider/main_scaffold_provider.dart';
import '../../../../album/data/model/work.dart';
import '../../../../overly-lyrics/presentation/widget/overly_setting_panel.dart';
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
    isTopBarLayerAlwaysVisible: false,
    hasSabGradient: false,
    navBarHeight: 0,
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
          if (workId == null) {
            KikoenaiToast.info("当前播放的歌曲不是DLsite中的作品或未解析，无法进行文件管理");
            return;
          }
          try {
            // 直接获取 FileNodeLibraryIndex，无需再 fromTree 转换
            FileNodeLibraryIndex index;
            if (track.isLocal) {
              // 处理本地逻辑
              final localIndex = FileScannerStorage()
                  .getWorkFileIndexLocally(workId);
              if (localIndex == null) {
                KikoenaiToast.warning("当前拿不到本地的音频数据，请查看音频是否被删除,或扫描是否完成");
                return; // 提前退出
              }
              index = localIndex;
            } else {
              index = await ref.read(trackFileNodeIndexProvider(workId).future);
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
      extra: {
        'workId': workId,
        if (work != null) 'work': work,
        'isLocal': track.isLocal,
      },
    );
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
