import 'package:flutter/material.dart';
import 'package:kikoenai/features/player/presentation/widget/video/player_video_controls_overlay.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../../core/service/player/player_service.dart';

class PlayerVideoContent extends StatefulWidget {
  const PlayerVideoContent({super.key});

  @override
  State<PlayerVideoContent> createState() => _PlayerVideoContentState();
}

class _PlayerVideoContentState extends State<PlayerVideoContent> {
  late final VideoController _videoController;
  final playerService = PlayerService.instance;

  @override
  void initState() {
    super.initState();
    _videoController = PlayerService.instance.videoController;
  }

  @override
  void dispose() {
    super.dispose();
    playerService.toggleVideoDecoding(false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
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