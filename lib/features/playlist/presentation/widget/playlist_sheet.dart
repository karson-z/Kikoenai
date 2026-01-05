import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'dart:math' as math;
import '../../../../core/widgets/common/custom_bottom_type.dart';
import '../../../../core/widgets/common/custom_side_sheet_type.dart';
import '../../../settings/presentation/provider/setting_provider.dart';
import '../../data/model/playlist.dart';
import '../provider/playlist_provider.dart';

class PlaylistSheet {
  static Future<void> show(
      BuildContext context, {
        bool? isDark,
        VoidCallback? onClosed,
      }) {
    return WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: (_) {
        final width = MediaQuery.of(context).size.width;
        return width < 500 ? const CustomBottomType() : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) {
        final isDarkMode = isDark ?? Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
        final titleColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.white70 : Colors.grey;
        final iconColor = isDarkMode ? Colors.white70 : Colors.black54;
        final minSheetHeight = MediaQuery.of(context).size.height * 0.5;

        return [
          SliverWoltModalSheetPage(
            backgroundColor: bgColor,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: Text(
              '我的歌单',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: titleColor),
            ),
            trailingNavBarWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: titleColor,
                tooltip: "新建歌单",
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: 处理新建逻辑
                },
              ),
            ),
            mainContentSliversBuilder: (context) => [
              const SliverPadding(padding: EdgeInsets.only(top: 12)),
              Consumer(
                builder: (_, ref, __) {
                  final asyncPlaylists = ref.watch(fetchPlaylistsProvider((page: 1, filterBy: 'all')));

                  return asyncPlaylists.when(
                    loading: () => SliverToBoxAdapter(
                      child: SizedBox(
                        height: minSheetHeight,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (err, stack) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: minSheetHeight,
                        child: Center(child: Text('加载失败: $err')),
                      ),
                    ),
                    data: (response) {
                      final playlists = response.playlists;

                      if (playlists.isEmpty) {
                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: minSheetHeight,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.album_outlined, size: 64, color: subtitleColor.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  Text("暂无歌单", style: TextStyle(color: subtitleColor)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverList.builder(
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return _buildPlaylistItem(
                                context,
                                ref,
                                playlist,
                                titleColor,
                                subtitleColor,
                                iconColor,
                              );
                            },
                          ),
                          SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final paintedHeight = constraints.precedingScrollExtent;
                              final remainingHeight = minSheetHeight - paintedHeight;
                              return SliverToBoxAdapter(
                                child: SizedBox(height: math.max(0, remainingHeight)),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ];
      },
    ).whenComplete(() {
      if (onClosed != null) onClosed();
    });
  }

  static Widget _buildPlaylistItem(
      BuildContext context,
      WidgetRef ref,
      Playlist playlist,
      Color titleColor,
      Color subtitleColor,
      Color iconColor,
      ) {
    String displayName = playlist.name;
    displayName = OtherUtil.getDisplayName(displayName);

    final bool hasValidCover = playlist.mainCoverUrl != null && playlist.mainCoverUrl!.startsWith('http');

    // 获取当前选中的播放列表，用于高亮显示（可选优化）
    final currentTarget = ref.watch(defaultMarkTargetPlaylistProvider);
    final isSelected = currentTarget?.id == playlist.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      // 可选：如果被选中，背景稍微变色
      selected: isSelected,
      selectedTileColor: titleColor.withOpacity(0.05),

      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withOpacity(0.1),
          image: hasValidCover
              ? DecorationImage(
            image: NetworkImage(playlist.mainCoverUrl!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: !hasValidCover
            ? Icon(Icons.music_note_rounded, color: iconColor)
            : null,
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? Theme.of(context).primaryColor : titleColor, // 选中变色
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            if (playlist.privacy == 1) ...[
              Icon(Icons.lock_outline, size: 12, color: subtitleColor),
              const SizedBox(width: 4),
            ],
            Text(
              '${playlist.worksCount} 首作品',
              style: TextStyle(fontSize: 12, color: subtitleColor),
            ),
          ],
        ),
      ),
      onTap: () {
        ref.read(defaultMarkTargetPlaylistProvider.notifier).setPlaylist(playlist);

        Navigator.of(context).pop();
      },
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: iconColor, size: 20),
        onPressed: () {},
      ),
    );
  }
}