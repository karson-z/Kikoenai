
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kikoenai/features/player/presentation/widget/player_controls.dart';
import 'package:kikoenai/features/player/presentation/widget/player_info.dart';

import '../../../../core/widgets/image_box/simple_extended_image.dart';
import '../../../../core/widgets/player/player_progress_bar.dart';

class MobileAlbumContent extends ConsumerWidget {
  final MediaItem? track;
  const MobileAlbumContent({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这里只关心内容布局，不再关心自己在屏幕的哪里
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(height: 350),
        PlayerInfoWidget(track: track),
        const PlayerProgressBar(),
        const PlayerControls(),
        const PlayerVolumeSlider(),
      ],
    );
  }
}

class FloatingCoverImage extends StatelessWidget {
  final String? url;
  final double radiusValue;

  const FloatingCoverImage({super.key, this.url, required this.radiusValue});

  @override
  Widget build(BuildContext context) {
    // 这是一个很纯粹的组件，只负责渲染图片和圆角阴影
    // 它的大小由 LayoutDelegate 传入的 BoxConstraints 决定
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusValue),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: SimpleExtendedImage(
          url ?? '',
          borderRadius: BorderRadius.circular(radiusValue),
          fit: BoxFit.cover
      ),
    );
  }
}