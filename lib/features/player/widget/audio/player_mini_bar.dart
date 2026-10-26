import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/widget/audio/player_controls.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../provider/player_controller_provider.dart';

class CollapsedMinibar extends ConsumerWidget {
  final PlaybackItem? track;
  final VoidCallback onTap;
  final double coverRight;

  const CollapsedMinibar({
    super.key,
    required this.track,
    required this.onTap,
    this.coverRight = 76,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playerControllerProvider.select((state) => state.progressBarState),
    );
    final total = progress.total.inMilliseconds;
    final value = total <= 0
        ? 0.0
        : (progress.current.inMilliseconds / total).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Row(
                children: [
                  SizedBox(width: coverRight + 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track?.title ?? "未播放",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          track?.artist ?? "未知艺人",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.5,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: MiniControlButtons(),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 2,
                  semanticsLabel: '播放进度',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
