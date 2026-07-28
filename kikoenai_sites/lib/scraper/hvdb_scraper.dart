import 'package:html/parser.dart' show parse;

import 'scraper_http_client.dart';
import 'scraper_utils.dart';

/// HVDB 元数据爬虫。
class HvdbScraper {
  HvdbScraper._();

  static Future<Map<String, dynamic>> scrapeWorkMetadata(
    int id, {
    ScraperCancellationToken? cancellationToken,
  }) async {
    final url = 'https://hvdb.me/Dashboard/WorkDetails/$id';

    try {
      final response = await ScraperHttpClient.retryGet(
        url,
        cancellationToken: cancellationToken,
      );
      final document = parse(response.data);

      final Map<String, dynamic> work = {
        'id': id,
        'tags': <Map<String, dynamic>>[],
        'vas': <Map<String, dynamic>>[],
      };

      final nameInput = document.querySelector('input#Name');
      if (nameInput != null) work['title'] = nameInput.attributes['value'];

      final sfwInput = document.querySelector('input[name="SFW"]');
      if (sfwInput != null) {
        work['nsfw'] = sfwInput.attributes['value'] == 'false';
      }

      document.querySelectorAll('a').forEach((element) {
        final href = element.attributes['href'] ?? '';
        final text = element.text.trim();

        if (href.contains('CircleWorks')) {
          work['circle'] = {'id': href.split('/').last, 'name': text};
        } else if (href.contains('TagWorks')) {
          (work['tags'] as List).add({
            'id': href.split('/').last,
            'name': text,
          });
        } else if (href.contains('CVWorks')) {
          (work['vas'] as List).add({
            'id': ScraperUtils.nameToUUID(text),
            'name': text,
          });
        }
      });

      if ((work['tags'] as List).isEmpty && (work['vas'] as List).isEmpty) {
        throw Exception("Couldn't parse data from HVDB work page.");
      }

      return work;
    } catch (e) {
      // 调用方应做兜底，这里直接 rethrow
      rethrow;
    }
  }
}
