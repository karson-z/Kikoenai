import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/data/colors_util.dart';
import '../../../../core/widgets/layout/provider/main_scaffold_provider.dart';

class PlayerBackground extends ConsumerWidget {
  const PlayerBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = ref.watch(mainScaffoldProvider);
    final themeBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 构建渐变色
    final gradient = ColorUtils.buildGradient(
      start: bg.dominantColor,
      end: bg.vibrantColor.withOpacity(0.6),
      begin: Alignment.topCenter,
      endAlign: Alignment.bottomCenter,
    );

    // 这一层是为了配合拖拽进度做颜色插值（如果需要的话）
    // 但在新的架构中，背景通常保持静态或随状态缓慢变化，
    // 这里的实现复用了原有的逻辑
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // 这里的颜色逻辑可以根据需要微调，保持原有的视觉效果
              Color.lerp(themeBackgroundColor, bg.dominantColor, 0.5)!,
              Color.lerp(themeBackgroundColor, bg.vibrantColor.withOpacity(0.6), 0.5)!,
            ],
          ),
        ),
      ),
    );
  }
}