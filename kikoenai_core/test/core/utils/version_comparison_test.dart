import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_core/core/utils/other.dart';

void main() {
  test('compares GitHub v-prefixed release tags', () {
    expect(OtherUtil.needUpdate('1.1.0', 'v1.1.1'), isTrue);
    expect(OtherUtil.needUpdate('1.1.0', 'v1.1.0'), isFalse);
    expect(OtherUtil.needUpdate('1.1.0', 'v1.0.9'), isFalse);
  });

  test('compares major and minor releases numerically', () {
    expect(OtherUtil.needUpdate('1.9.9', '2.0.0'), isTrue);
    expect(OtherUtil.needUpdate('1.9.9', '1.10.0'), isTrue);
  });
}
