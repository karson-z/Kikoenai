import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/widget/video/player_video_controls_overlay.dart';
import 'package:kikoenai/features/player/widget/video/player_video_gesture_layer.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../../core/storage/hive_key.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../provider/player_controller_provider.dart';
import '../../../../../core/service/player/player_service.dart';

class PlayerVideoContent extends ConsumerStatefulWidget {
  final bool isMini;

  const PlayerVideoContent({super.key, this.isMini = false});

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
    return ValueListenableBuilder(
      valueListenable: AppStorage.settingsBox.listenable(
        keys: [StorageKeys.playerPlayInBackground],
      ),
      builder: (context, box, child) {
        final playInBackground =
            box.get(StorageKeys.playerPlayInBackground, defaultValue: true)
                as bool;

        return Container(
          color: widget.isMini ? Colors.transparent : Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(
                controller: _videoController,
                controls: NoVideoControls,
                pauseUponEnteringBackgroundMode: !playInBackground,
                resumeUponEnteringForegroundMode: false,
                fit: widget.isMini ? BoxFit.contain : BoxFit.contain,
                fill: Colors.transparent,
              ),

              if (!widget.isMini) ...[
                const VideoGestureLayer(child: SizedBox.expand()),
                const PlayerVideoControlsOverlay(),
              ],
            ],
          ),
        );
      },
    );
  }
}
