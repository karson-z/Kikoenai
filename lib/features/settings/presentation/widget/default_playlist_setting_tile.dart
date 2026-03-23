import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/auth/presentation/view_models/provider/auth_provider.dart';

import '../../../../core/utils/data/other.dart';
import '../../../playlist/data/model/playlist.dart';
import '../provider/setting_provider.dart';

class DefaultPlaylistSettingTile extends ConsumerWidget {
  const DefaultPlaylistSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 1. 使用扩展方法直接获取登录状态
    final bool isLogin = ref.isLoggedIn;

    final selectedPlaylist = ref.watch(defaultMarkTargetPlaylistProvider);
    final playlistsAsync = ref.watch(allMyPlaylistsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add_check, size: 24, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '默认播放列表',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '点击作品卡片右上角按钮后，作品将被添加到这个播放列表',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // --- 核心逻辑判断 ---
          if (!isLogin)
          // 未登录状态：直接显示请登录，跳过网络请求解析
            Text(
              "请登录",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            )
          else
          // 已登录状态：处理异步列表数据
            playlistsAsync.when(
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(
                "加载失败",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
              data: (playlists) {
                // 如果登录了但没有歌单，提示无可用列表
                if (playlists.isEmpty) {
                  return Text("无可用列表", style: theme.textTheme.bodyMedium);
                }

                final String? currentId = selectedPlaylist?.id;
                final bool isValid = playlists.any((p) => p.id == currentId);

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    focusColor: Colors.transparent,
                    value: isValid ? currentId : null,
                    hint: const Text("请选择..."),
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 400,
                    items: playlists.map<DropdownMenuItem<String>>((Playlist playlist) {
                      final displayName = OtherUtil.getDisplayName(playlist.name);
                      return DropdownMenuItem<String>(
                        value: playlist.id,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newId) {
                      if (newId != null) {
                        final newPlaylist = playlists.firstWhere((p) => p.id == newId);
                        ref.read(defaultMarkTargetPlaylistProvider.notifier).setPlaylist(newPlaylist);
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}