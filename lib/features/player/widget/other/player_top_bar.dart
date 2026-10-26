import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/widget/other/player_more_options_sheet.dart';
import 'package:kikoenai/features/player/widget/other/player_sleep_time_widget.dart';
import '../../provider/player_controller_provider.dart';

class TopBar extends ConsumerWidget {
  final VoidCallback onClose;

  const TopBar({
    super.key,
    required this.onClose,
    this.showTitle = false,
    this.selectedPage = 0,
    this.onSelectPage,
  });

  final bool showTitle;
  final int selectedPage;
  final ValueChanged<int>? onSelectPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = ref.watch(
      playerControllerProvider.select((s) => s.currentItem),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showTitle)
            const Text(
              '正在播放',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          Row(
            children: [
              // 左侧：下拉关闭
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: onClose,
              ),
              Expanded(
                child: onSelectPage != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var page = 0; page < 2; page++)
                            Flexible(
                              child: Semantics(
                                selected: selectedPage == page,
                                child: TextButton(
                                  key: ValueKey('player-tab-$page'),
                                  onPressed: () => onSelectPage!(page),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    foregroundColor: selectedPage == page
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(page == 0 ? '播放' : '歌词'),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // 右侧：功能按钮组
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SleepTimerButton(),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () {
                      showMoreOptions(context, ref, currentItem);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
