import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  test('parses an RJ code from a folder name', () {
    expect(RjCode.parse('RJ01234567'), 1234567);
    expect(RjCode.parse('[RJ01231231]'), 1231231);
    expect(RjCode.parse('(RJ01234567)'), 1234567);
    expect(RjCode.parse('RJ01234567 音声'), 1234567);
    expect(RjCode.parse('RJ01234'), 1234);
    expect(RjCode.parse('RJ0123456789'), 123456789);
    expect(
      RjCode.parse('[RJ103592]妹ボイス～お兄ちゃんお姉ちゃんへ～'),
      103592,
    );
  });

  test('rejects a prefixed or overlong RJ code', () {
    expect(RjCode.parse('XRJ01234567'), isNull);
    expect(RjCode.parse('RJ12345678901'), isNull);
  });

  test('collects every RJ code in a folder name', () {
    expect(RjCode.parseAll('RJ01234567 and RJ12345678'), {1234567, 12345678});
    expect(RjCode.parseAll('XRJ01234567'), isEmpty);
  });
}
