import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/scraper/scraper_utils.dart';

void main() {
  group('toRjCode', () {
    test('pads short ids to the 6-digit form', () {
      expect(ScraperUtils.toRjCode(97514), 'RJ097514');
      expect(ScraperUtils.toRjCode(1234), 'RJ001234');
    });

    test('keeps a 6-digit id unchanged', () {
      expect(ScraperUtils.toRjCode(123456), 'RJ123456');
    });

    test('pads a 7-digit id to the 8-digit form', () {
      expect(ScraperUtils.toRjCode(1234567), 'RJ01234567');
      expect(ScraperUtils.toRjCode(1059771), 'RJ01059771');
    });

    test('keeps an 8-digit id unchanged', () {
      expect(ScraperUtils.toRjCode(12345678), 'RJ12345678');
    });
  });
}
