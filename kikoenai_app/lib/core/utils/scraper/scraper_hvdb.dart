import 'package:html/parser.dart' show parse;
import 'package:kikoenai/core/utils/scraper/scraper_dio.dart';
import 'package:kikoenai/core/utils/scraper/scraper_util.dart';

class HvdbScraper {
  static Future<Map<String, dynamic>> scrapeWorkMetadata(int id) async {
    final rjcode = ScraperUtils.toRjCode(id);
    final url = "https://hvdb.me/Dashboard/WorkDetails/$id";

    print('[RJ$rjcode] 从 HVDB 抓取元数据...');

    try {
      final response = await DioClient.retryGet(url);
      final document = parse(response.data);

      final Map<String, dynamic> work = {
        'id': id,
        'tags': [],
        'vas': [],
      };

      // 解析标题和 NSFW
      final nameInput = document.querySelector('input#Name');
      if (nameInput != null) work['title'] = nameInput.attributes['value'];

      final sfwInput = document.querySelector('input[name="SFW"]');
      if (sfwInput != null) work['nsfw'] = sfwInput.attributes['value'] == 'false';

      // 解析社团、标签、声优
      document.querySelectorAll('a').forEach((element) {
        final href = element.attributes['href'] ?? '';
        final text = element.text.trim();

        if (href.contains('CircleWorks')) {
          work['circle'] = {
            'id': href.split('/').last,
            'name': text,
          };
        } else if (href.contains('TagWorks')) {
          work['tags'].add({
            'id': href.split('/').last,
            'name': text,
          });
        } else if (href.contains('CVWorks')) {
          work['vas'].add({
            'id': ScraperUtils.nameToUUID(text),
            'name': text,
          });
        }
      });

      if ((work['tags'] as List).isEmpty && (work['vas'] as List).isEmpty) {
        throw Exception("Couldn't parse data from HVDB work page.");
      }

      print('[RJ$rjcode] 成功从 HVDB 抓取元数据');
      return work;
    } catch (e) {
      rethrow;
    }
  }
}