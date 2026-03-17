import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/service/audio/audio_service_media_kit.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/features/player/presentation/widget/player_more_widget.dart';
import 'package:kikoenai/features/player/presentation/widget/player_sleep_time_widget.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../provider/player_controller_provider.dart';



class TopBar extends ConsumerWidget {
  final VoidCallback onClose;

  const TopBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 左侧：下拉关闭
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 28),
              onPressed: onClose,
            ),
          ),

          // 右侧：功能按钮组
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SleepTimerButton(),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {
                    _showMoreOptions(context, currentTrack, ref);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, MediaItem? track, WidgetRef ref) {
    if (track == null) {
      KikoenaiToast.warning('当前没有播放中的歌曲');
      return;
    }

    // 判断当前音源是否包含视频 (需确保你存入了正确的 key)
    final bool isVideoTrack = track.extras?['isVideo'] == true;

    // 构建基础菜单列表
    final List<ListActionItem> dynamicListActions = [
      ListActionItem(
        icon: Icons.multitrack_audio_outlined,
        title: '忽略音频焦点',
        hasSwitch: true,
        initialSwitchValue: AppStorage.settingsBox.get(StorageKeys.ignoreAudioFocus, defaultValue: false),
        onSwitchChanged: (bool value) async {
          await AudioServiceSingleton.instance.customAction(
            'setIgnoreAudioFocus',
            {'ignore': value},
          );
        },
      ),
    ];

    // 如果是视频源，动态插入“仅音频模式”
    if (isVideoTrack) {
      // 从 Riverpod 读取当前内存中的开关状态
      final bool currentAudioOnlyState = ref.read(audioOnlyModeProvider);

      dynamicListActions.add(
        ListActionItem(
          icon: Icons.videocam_off_outlined,
          title: '仅音频模式',
          subtitle: '关闭视频画面以省电',
          hasSwitch: true,
          initialSwitchValue: currentAudioOnlyState,
          onSwitchChanged: (bool value) async {
            // 1. 更新 Riverpod 内存状态，保证重开弹窗时状态一致
            ref.read(audioOnlyModeProvider.notifier).toggleMode(value);

            // 2. 下发指令给底层：开启仅音频(value=true) 时关闭视频解码(enable=false)
            await AudioServiceSingleton.instance.customAction(
              'toggleVideoDecoding',
              {'enable': !value},
            );
          },
        ),
      );
    }

    // 追加常驻菜单项
    dynamicListActions.addAll([
      ListActionItem(
        icon: Icons.album_outlined,
        title: "专辑",
        subtitle: track.album,
        onTap: () {
          final workData = track.extras?['workData'];
          if(workData != null) {
            KikoenaiLogger().w('本地文件没有专辑信息哦！');
            return;
          }
          Navigator.pop(context);
          if (track.extras?['workData'] != null) {
            final panelCtrl = ref.read(panelController);
            if (panelCtrl.isPanelOpen) {
              panelCtrl.close();
            }
            context.push(AppRoutes.detail, extra: {'work': jsonDecode(track.extras!['workData'])});
          }
        },
      ),
      ListActionItem(
        icon: Icons.person_outline_rounded,
        title: "歌手",
        subtitle: track.artist,
        onTap: () {},
      ),
    ]);

    // 渲染 BottomSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MoreOptionsBottomSheet(
          track: track,
          quickActions: [
            QuickActionItem(
              icon: Icons.add_box_outlined,
              label: "收藏",
              onTap: () { Navigator.pop(context); },
            ),
            QuickActionItem(
              icon: Icons.download_for_offline_outlined,
              label: "下载",
              onTap: () {},
            ),
            QuickActionItem(
              icon: Icons.picture_in_picture_alt,
              label: "桌面字幕",
              onTap: () {},
            ),
          ],
          listActions: dynamicListActions,
        );
      },
    );
  }
}