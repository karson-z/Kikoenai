import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Target position while a video seek gesture is in progress.
///
/// Null means the progress bar should follow the real playback position.
/// The gesture seeks the player only when the drag ends.
class VideoSeekPreview extends Notifier<Duration?> {
  @override
  Duration? build() => null;

  void update(Duration position) {
    state = position;
  }

  void clear() {
    state = null;
  }
}

final videoSeekPreviewProvider =
    NotifierProvider<VideoSeekPreview, Duration?>(VideoSeekPreview.new);
