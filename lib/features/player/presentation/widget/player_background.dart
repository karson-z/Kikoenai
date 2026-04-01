import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
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
        // 图像与高斯模糊层始终保持完整不透明状态，避开 saveLayer 的逐帧重建消耗
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

        // 顶层覆盖纯色遮罩，随着面板展开，遮罩逐渐透明消失
        // 纯色容器的 Opacity 动画由 GPU 直接完成，不涉及复杂的像素读取
        IgnorePointer(
          child: Opacity(
            opacity: (1.0 - widget.expandedOpacity).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [startColor, endColor],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}