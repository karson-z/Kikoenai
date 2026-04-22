import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/presentation/widget/video/player_video_gesture_layer.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../provider/player_controller_provider.dart';
import '../../../../../core/service/player/player_service.dart';

class PlayerVideoContent extends ConsumerStatefulWidget {
  const PlayerVideoContent({super.key});

  @override
  ConsumerState<PlayerVideoContent> createState() => _PlayerVideoContentState();
}

class _PlayerVideoContentState extends ConsumerState<PlayerVideoContent> {
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = PlayerService.instance.videoController;
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoGestureLayer(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
              fit: BoxFit.contain,
              fill: Colors.transparent,
            ),
          ),
          const PlayerVideoControlsOverlay(),
        ],
      ),
    );
  }
}