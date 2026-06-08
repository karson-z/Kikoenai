import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/data/model/playback_session.dart';
import 'package:kikoenai/features/player/presentation/widget/audio/player_controls.dart';

class CollapsedMinibar extends ConsumerWidget {
  final PlaybackItem? track;
  final VoidCallback onTap;

  const CollapsedMinibar({super.key, required this.track, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double leftPadding = 16.0 + 60.0 + 12.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            const SizedBox(width: leftPadding),
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
                maxWidth: MediaQuery.sizeOf(context).width * 0.45,
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
      ),
    );
  }
}
