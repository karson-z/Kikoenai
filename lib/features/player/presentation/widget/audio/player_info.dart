import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class PlayerInfoWidget extends StatelessWidget {
  final MediaItem? track;

  const PlayerInfoWidget({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          TextScroll(
            track?.title ?? "没有播放的曲目",
            mode: TextScrollMode.endless,
            velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
            delayBefore: const Duration(seconds: 2),
            pauseBetween: const Duration(seconds: 2),
            fadedBorder: true,
            fadedBorderWidth: 0.1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            track?.artist ?? "未知艺人",
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}