import 'package:audio_service/audio_service.dart';

/// Prevents Android from receiving `playing=true` with `STATE_NONE`.
AudioProcessingState processingStateForPlayingEvent({
  required bool playing,
  required AudioProcessingState current,
}) {
  if (playing && current == AudioProcessingState.idle) {
    return AudioProcessingState.buffering;
  }
  return current;
}
