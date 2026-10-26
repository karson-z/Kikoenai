import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/lyrics/lyrics_parse_service.dart';

void main() {
  test(
    'unified subtitles grow with the reading region and keep depth effects',
    () {
      final phone = LyricStyleFactory.createStyle(viewportWidth: 390);
      final tabletPane = LyricStyleFactory.createStyle(viewportWidth: 460);
      final widePane = LyricStyleFactory.createStyle(viewportWidth: 752);

      expect(phone.textStyle.fontSize, 26);
      expect(phone.activeStyle.fontSize, 30);
      expect(
        tabletPane.textStyle.fontSize,
        greaterThan(phone.textStyle.fontSize!),
      );
      expect(widePane.textStyle.fontSize, 32);
      expect(widePane.activeStyle.fontSize, 38);
      expect(widePane.translationStyle.fontSize, 20);
      expect(widePane.lineGap, greaterThanOrEqualTo(phone.lineGap));
      expect(widePane.inactiveLineBlurRadius, greaterThan(0));
      expect(widePane.activeLineGlowRadius, greaterThan(0));
      expect(widePane.scrollBehavior, isA<SpringScrollConfig>());
    },
  );
}
