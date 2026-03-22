import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../../../core/utils/data/colors_util.dart';
import '../provider/player_controller_provider.dart';


class PlayerBackground extends ConsumerStatefulWidget {
  final double expandedOpacity;

  const PlayerBackground({
    super.key,
    required this.expandedOpacity,
  });

  @override
  ConsumerState<PlayerBackground> createState() => _PlayerBackgroundState();
}

class _PlayerBackgroundState extends ConsumerState<PlayerBackground> {
  // 1. 定义颜色状态，给予默认值（墨蓝色）
  final Color _dominantColor = const Color(0xFF001F3F);
  final Color _vibrantColor = const Color(0xFF001F3F);

  @override
  Widget build(BuildContext context) {
    final coverUrl = ref.watch(playerControllerProvider.select(
            (s) => s.currentTrack?.extras?['mainCoverUrl'] as String?
    ));
    final themeBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final double colorProgress = ((widget.expandedOpacity - 0.15) / 0.85).clamp(0.0, 1.0);
    final Color startColor = Color.lerp(
      themeBackgroundColor,
      _dominantColor,
      colorProgress,
    )!;
    final Color endColor = Color.lerp(
      themeBackgroundColor,
      _vibrantColor.withOpacity(0.6),
      colorProgress,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [startColor, endColor],
            ),
          ),
        ),
        if (widget.expandedOpacity > 0.01)
          Opacity(
            opacity: widget.expandedOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null && coverUrl.isNotEmpty)
                  SimpleExtendedImage(
                    coverUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),

                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      // 静态深色遮罩，保证文字清晰
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}