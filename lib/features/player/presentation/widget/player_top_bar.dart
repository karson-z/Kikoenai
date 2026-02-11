import 'dart:convert';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../core/widgets/player/player_more_widget.dart';
import '../../../../core/widgets/player/player_sleep_time_widget.dart';
import '../../../../core/widgets/player/provider/player_controller_provider.dart';

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
                    // 这里的 showMoreOptions 需要你是以前的方法，
                    // 或者你可以把 showMoreOptions 逻辑也做成静态方法或 Mixin
                    _showMoreOptions(context, currentTrack);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 简单的 Helper 方法，复用原有的逻辑
  void _showMoreOptions(BuildContext context, MediaItem? track) {
    if (track == null) {
      KikoenaiToast.warning('当前没有播放中的歌曲');
      return;
    }
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
          listActions: [
            ListActionItem(
              icon: Icons.album_outlined,
              title: "专辑",
              subtitle: track.album,
              onTap: () {
                Navigator.pop(context);
                // 路由跳转逻辑需要 context 和 ref，这里简化处理
                if (track.extras?['workData'] != null) {
                  context.go(AppRoutes.detail, extra: {'work': jsonDecode(track.extras!['workData'])});
                }
              },
            ),
            ListActionItem(
              icon: Icons.person_outline_rounded,
              title: "歌手",
              subtitle: track.artist,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}