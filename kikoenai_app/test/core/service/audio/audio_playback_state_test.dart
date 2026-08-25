import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/audio/audio_playback_state.dart';

void main() {
  group('processingStateForPlayingEvent', () {
    test('uses buffering when initial playback starts from idle', () {
      final state = processingStateForPlayingEvent(
        playing: true,
        current: AudioProcessingState.idle,
      );

      expect(state, AudioProcessingState.buffering);
    });

    test('preserves ready when playback resumes', () {
      final state = processingStateForPlayingEvent(
        playing: true,
        current: AudioProcessingState.ready,
      );

      expect(state, AudioProcessingState.ready);
    });

    test('preserves idle while not playing', () {
      final state = processingStateForPlayingEvent(
        playing: false,
        current: AudioProcessingState.idle,
      );

      expect(state, AudioProcessingState.idle);
    });
  });
}
