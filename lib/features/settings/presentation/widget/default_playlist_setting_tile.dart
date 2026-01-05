import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/data/other.dart';
import '../../../playlist/data/model/playlist.dart';
import '../provider/setting_provider.dart';

class DefaultPlaylistSettingTile extends ConsumerWidget {
  const DefaultPlaylistSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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

          // --- 3. 尾部控件 (Dropdown / Loading) ---
          playlistsAsync.when(
            // 加载中
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            // 加载失败
            error: (_, __) => Text(
              "加载失败",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
            // 加载成功
            data: (playlists) {
              if (playlists.isEmpty) {
                return Text("无播放列表", style: theme.textTheme.bodyMedium);
              }

              // 核心逻辑：校验当前选中的 ID 是否有效
              final String? currentId = selectedPlaylist?.id;
              // 检查 currentId 是否确实存在于网络返回的列表中
              final bool isValid = playlists.any((p) => p.id == currentId);

              // 下拉菜单
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isValid ? currentId : null,
                  hint: Text(
                    isValid ? (selectedPlaylist?.name ?? "请选择...") : "请选择...",
                  ),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  borderRadius: BorderRadius.circular(12),
                  menuMaxHeight: 400, // 限制菜单高度
                  items: playlists.map((Playlist playlist) {
                    final displayName = OtherUtil.getDisplayName(playlist.name);
                    return DropdownMenuItem<String>(
                      value: playlist.id, // 这里的 value 必须和上面的 value 类型一致
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