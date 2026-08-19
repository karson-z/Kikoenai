import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/lyrics/lyrics_parse_service.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  test('app lyric settings customize the Apple Music preset', () {
    const config = LyricConfigModel(
      mainFontSize: 26,
      transFontSize: 14,
      activeFontSize: 31,
      lineGap: 28,
      translationGap: 7,
    );

    final style = LyricStyleFactory.createStyle(config);

    expect(style.textStyle.fontSize, 26);
    expect(style.translationStyle.fontSize, 14);
    expect(style.activeStyle.fontSize, 31);
    expect(style.lineGap, 28);
    expect(style.translationLineGap, 7);
    expect(style.inactiveLineBlurRadius, greaterThan(0));
    expect(style.activeLineGlowRadius, greaterThan(0));
    expect(style.scrollBehavior, isA<SpringScrollConfig>());
  });
}
