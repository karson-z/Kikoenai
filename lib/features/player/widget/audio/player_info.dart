import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:text_scroll/text_scroll.dart';

class PlayerInfoWidget extends StatelessWidget {
  final PlaybackItem? track;

  const PlayerInfoWidget({
    super.key,
    required this.track,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          TextScroll(
            track?.title ?? "没有播放的曲目",
            mode: TextScrollMode.endless,
            velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
            delayBefore: const Duration(seconds: 2),
            pauseBetween: const Duration(seconds: 2),
            fadedBorder: true,
            fadedBorderWidth: 0.1,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 18 : 22,
              height: 1.3,
              fontWeight: FontWeight.bold,
            ),
            textAlign: compact ? TextAlign.start : TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            track?.artist ?? "未知艺人",
            textAlign: compact ? TextAlign.start : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: compact ? 12 : 16,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
