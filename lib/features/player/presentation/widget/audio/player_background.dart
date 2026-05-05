import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../provider/player_controller_provider.dart';

class PlayerBackground extends ConsumerWidget {
  final double expandedOpacity;

  const PlayerBackground({
    super.key,
    required this.expandedOpacity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = ref.watch(playerControllerProvider.select(
          (s) => s.currentTrack?.extras?['mainCoverUrl'] as String?,
    ));
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
        IgnorePointer(
          child: Opacity(
            opacity: (1.0 - expandedOpacity).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}