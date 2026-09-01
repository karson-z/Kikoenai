import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/audio/audio_service.dart';

void main() {
  group('desktop lyric media controls', () {
    test(
      'inserts both Android actions without changing compact action order',
      () {
        final controls = buildPlaybackControls(
          playing: true,
          desktopLyricsEnabled: false,
          clickThroughEnabled: false,
          includeOverlayLyricsControls: true,
        );

        expect(controls, hasLength(5));
        expect(controls[0].action, MediaAction.skipToPrevious);
        expect(controls[1].action, MediaAction.pause);
        expect(
          controls[2].customAction?.name,
          OverlayLyricsMediaAction.toggleVisibility,
        );
        expect(controls[2].label, '显示桌面歌词');
        expect(
          controls[2].androidIcon,
          'drawable/ic_desktop_lyrics_visibility',
        );
        expect(controls[3].action, MediaAction.skipToNext);
        expect(
          controls[4].customAction?.name,
          OverlayLyricsMediaAction.toggleClickThrough,
        );
        expect(controls[4].label, '开启歌词点击穿透');
        expect(controls[4].androidIcon, 'drawable/ic_desktop_lyrics_lock');
      },
    );

    test('uses inverse actions when lyrics and click-through are enabled', () {
      final controls = buildPlaybackControls(
        playing: false,
        desktopLyricsEnabled: true,
        clickThroughEnabled: true,
        includeOverlayLyricsControls: true,
      );

      expect(controls[1].action, MediaAction.play);
      expect(controls[2].label, '隐藏桌面歌词');
      expect(
        controls[2].androidIcon,
        'drawable/ic_desktop_lyrics_visibility_off',
      );
      expect(controls[4].label, '关闭歌词点击穿透');
      expect(controls[4].androidIcon, 'drawable/ic_desktop_lyrics_unlock');
    });

    test('keeps unsupported platforms on standard playback controls', () {
      final controls = buildPlaybackControls(
        playing: false,
        desktopLyricsEnabled: true,
        clickThroughEnabled: true,
        includeOverlayLyricsControls: false,
      );

      expect(controls.map((control) => control.action), [
        MediaAction.skipToPrevious,
        MediaAction.play,
        MediaAction.skipToNext,
      ]);
    });
  });
}
