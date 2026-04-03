
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kikoenai/features/player/presentation/widget/audio/player_controls.dart';
import 'package:kikoenai/features/player/presentation/widget/audio/player_info.dart';
import 'package:kikoenai/features/player/presentation/widget/other/player_progress_bar.dart';

class PlayerAlbumContent extends ConsumerWidget {
  final MediaItem? track;
  const PlayerAlbumContent({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

