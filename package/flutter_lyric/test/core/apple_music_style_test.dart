import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appleMusic preset exposes the depth and motion treatment', () {
    final style = LyricStyles.appleMusic;

    expect(style.contentAlignment, CrossAxisAlignment.start);
    expect(style.activeStyle.fontSize, greaterThan(style.textStyle.fontSize!));
    expect(style.inactiveLineBlurRadius, greaterThan(0));
    expect(style.activeLineGlowRadius, greaterThan(0));
    expect(style.activeLineGlowOpacity, inInclusiveRange(0, 1));
    expect(style.scrollBehavior, isA<SpringScrollConfig>());
    expect(style.highlightTransitionDuration, const Duration(milliseconds: 90));
  });

  test(
    'copyWith keeps Apple-only effects while allowing typography changes',
    () {
      final original = LyricStyles.appleMusic;
      final changed = original.copyWith(
        textStyle: original.textStyle.copyWith(fontSize: 27),
        lineGap: 30,
      );

      expect(changed.textStyle.fontSize, 27);
      expect(changed.lineGap, 30);
      expect(changed.inactiveLineBlurRadius, original.inactiveLineBlurRadius);
      expect(changed.activeLineGlowRadius, original.activeLineGlowRadius);
      expect(changed.scrollBehavior, same(original.scrollBehavior));
    },
  );

  testWidgets('Apple style paints timed words and animates between lines', (
    tester,
  ) async {
    final controller = LyricController()
      ..loadLyric('''
[0,2000]Hello(0,800) world(800,1200)
[2000,2000]Next(2000,900) line(2900,1100)
''')
      ..setProgress(const Duration(milliseconds: 500));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: Colors.black,
          child: SizedBox(
            width: 320,
            height: 480,
            child: LyricView(
              controller: controller,
              style: LyricStyles.appleMusic,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);

    controller.setProgress(const Duration(milliseconds: 2400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.activeIndexNotifiter.value, 1);
    expect(tester.takeException(), isNull);
  });
}
