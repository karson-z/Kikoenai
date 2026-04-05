import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/service/audio/audio_extension.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_more_widget.dart';

import '../../../../../core/model/file_node.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../../core/service/download/download_service.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../../../../core/utils/log/kikoenai_log.dart';
import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../../../../core/widgets/common/kikoenai_dialog.dart';
import '../../../../../core/widgets/common/manage_playlist_dialog.dart';
import '../../../../../core/widgets/layout/app_main_scaffold.dart';
import '../../../../../core/widgets/layout/app_toast.dart';
import '../../../../album/data/model/work.dart';
import '../../../../album/presentation/viewmodel/provider/audio_file_provider.dart';
import '../../../../download/presentation/provider/download_provider.dart';
import '../../../../overly-lyrics/presentation/widget/overly_setting_panel.dart';
import '../../provider/player_controller_provider.dart'; // 假设使用了 go_router


void showMoreOptions(BuildContext context, MediaItem? track) {
  // 直接调用封装好的组件
  KikoenaiDialog.showBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => PlayerMoreOptionsSheet(track: track),
  );
}
class PlayerMoreOptionsSheet extends ConsumerWidget {
  final MediaItem? track;

  const PlayerMoreOptionsSheet({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 状态检查
    if (track == null) {
      // 在 Widget 构建阶段不宜直接弹 Toast，建议在调用处判断或在 initState 中处理
      // 这里为了保持原有逻辑，使用 WidgetsBindingEndOfFrame
      // 但最佳实践是在调用 show 之前判断。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        KikoenaiToast.warning('当前没有播放中的歌曲');
        // 自动关闭空内容的 BottomSheet
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    // 2. 数据准备
    final isAudioOnly = ref.watch(
      playerControllerProvider.select((s) => s.isAudioOnly),
    );

    final workJson = track!.extras?['workData'];
    final work = workJson != null ? Work.fromJson(jsonDecode(workJson)) : null;
    final rjCode = work?.id;
    final bool isVideoTrack = track!.extras?['isVideo'] == true;

    // 3. 构建菜单列表
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
          await AudioServiceSingleton.instance.customAction(
            'setIgnoreAudioFocus',
            {'ignore': value},
          );
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
          },
        ),
      );
    }

    dynamicListActions.addAll([
      ListActionItem(
        icon: Icons.album_outlined,
        title: "专辑",
        subtitle: track!.album,
        onTap: () => _handleAlbumTap(context, ref, track!),
      ),
      ListActionItem(
        icon: Icons.person_outline_rounded,
        title: "歌手",
        subtitle: track!.artist,
      ),
    ]);

    // 4. 渲染 UI
    return BackButtonPriorityWrapper(
      zIndex: 100,
      name: 'PlayerMoreOptionsBottomSheet',
      child: MoreOptionsBottomSheet(
        track: track!,
        quickActions: _buildQuickActions(context, ref, work, rjCode),
        listActions: dynamicListActions,
      ),
    );
  }

  // 构建快捷操作按钮
  List<QuickActionItem> _buildQuickActions(
      BuildContext context,
      WidgetRef ref,
      Work? work,
      int? rjCode,
      ) {
    return [
      QuickActionItem(
        icon: Icons.favorite_border,
        label: "收藏",
        onTap: () => Navigator.pop(context),
      ),
      QuickActionItem(
        icon: Icons.folder_open_outlined,
        label: "文件管理",
        onTap: () => _handleFileManage(context, ref, rjCode, work),
      ),
      QuickActionItem(
        icon: Icons.picture_in_picture_alt,
        label: "桌面字幕",
        onTap: () => _handleSubtitleConfig(context),
      ),
    ];
  }

  // 处理专辑点击
  void _handleAlbumTap(BuildContext context, WidgetRef ref, MediaItem track) {
    Navigator.pop(context);
    if (track.isLocal) {
      KikoenaiLogger().i("本地轨道，跳转至文件目录或本地索引");
    } else {
      final workDataJson = track.extras?['workData'];
      if (workDataJson != null) {
        final panelCtrl = ref.read(panelControllerProvider);
        if (panelCtrl.isPanelOpen) panelCtrl.close();

        context.push(AppRoutes.detail, extra: {'work': jsonDecode(workDataJson)});
      }
    }
  }

  // 处理文件管理逻辑
  Future<void> _handleFileManage(
      BuildContext context,
      WidgetRef ref,
      int? rjCode,
      Work? work,
      ) async {
    Navigator.pop(context); // 关闭当前 BottomSheet

    if (rjCode == null) return;

    try {
      // 异步读取文件树
      final roots = await ref.read(trackFileNodeProvider(rjCode).future);

      // 读取已下载记录
      final downloadedTasks = ref.read(completedTasksProvider);
      final downloadedIds = downloadedTasks.map((t) => t.task.taskId).toSet();

      if (!context.mounted) return;

      FileTreeDialogExtension.showFileTree(
        context: context,
        roots: roots,
        disabledIds: downloadedIds,
        onDownload: (List<FileNode> selectedFiles) {
          DownloadService.instance.enqueueBatch(
            selectedFiles: selectedFiles,
            rootNodes: roots,
            title: work?.title ?? '未知作品',
            metaData: work?.toJson(),
          );
          KikoenaiToast.success("已加入下载队列");
        },
        onAddToQueue: (List<FileNode> selectedFiles) {
          final audioFiles = selectedFiles.where((f) => f.isAudio).toList();
          if (audioFiles.isNotEmpty && work != null) {
            ref.read(playerControllerProvider.notifier).addMultiInQueue(audioFiles, work);
            KikoenaiToast.success("成功添加该列表");
          }
          KikoenaiDialog.dismiss();
        },
      );
    } catch (e) {
      if (context.mounted) {
        KikoenaiToast.error("获取文件列表失败");
      }
    }
  }

  // 处理桌面字幕配置
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
