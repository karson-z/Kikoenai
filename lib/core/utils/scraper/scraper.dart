import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart' show parse;
import 'package:kikoenai/core/utils/scraper/scraper_dio.dart';
import 'package:kikoenai/core/utils/scraper/scraper_hvdb.dart';
import 'package:kikoenai/core/utils/scraper/scraper_util.dart';

class DlSiteScraper {
  /// 对应 scrapeStaticWorkMetadataFromDLsite
  static Future<Map<String, dynamic>> scrapeStatic(int id, String language) async {
    final String rjcode = ScraperUtils.toRjCode(id);

    final String url = 'https://www.dlsite.com/maniax/work/=/product_id/$rjcode.html';
    debugPrint('当前页面请求路径为：$url');
    String ageLabel, genreLabel, vaLabel, releaseLabel, seriesLabel, cookieLocale;

    switch (language) {
      case 'ja-jp':
        cookieLocale = 'locale=ja-jp';
        ageLabel = '年齢指定'; genreLabel = 'ジャンル'; vaLabel = '声優';
        releaseLabel = '販売日'; seriesLabel = 'シリーズ名';
        break;
      case 'zh-tw':
        cookieLocale = 'locale=zh-tw';
        ageLabel = '年齡指定'; genreLabel = '分類'; vaLabel = '聲優';
        releaseLabel = '販賣日'; seriesLabel = '系列名';
        break;
      default:
        cookieLocale = 'locale=zh-cn';
        ageLabel = '年龄指定'; genreLabel = '分类'; vaLabel = '声优';
        releaseLabel = '贩卖日'; seriesLabel = '系列名';
    }

    final response = await DioClient.retryGet(
        url,
        headers: {'cookie': cookieLocale}
    );
    final document = parse(response.data);

    final Map<String, dynamic> work = {
      'id': id,
      'rjCode': rjcode,
      'tags': [],
      'vas': [],
    };

    // 标题解析与清洗
    var title = document.querySelector('meta[property="og:title"]')?.attributes['content'];
    title ??= document.querySelector('a[href="$url"] span')?.text;
    work['title'] = title?.replaceFirst(RegExp(r' \[.+\] \| DLsite$'), '');

    // 社团解析
    final circleA = document.querySelector('span.maker_name a');
    if (circleA != null) {
      final href = circleA.attributes['href'] ?? '';
      work['circle'] = {
        'id': int.tryParse(href.substring(href.length - 10, href.length - 5)),
        'name': circleA.text,
      };
    }

    // 详情表单解析
    final outline = document.querySelector('#work_outline');
    if (outline != null) {
      final rows = outline.querySelectorAll('tr');
      for (var row in rows) {
        final thText = row.querySelector('th')?.text.trim();
        final td = row.querySelector('td');
        if (td == null) continue;

        if (thText == ageLabel) {
          work['nsfw'] = td.querySelector('span')?.text == '18禁';
        } else if (thText == releaseLabel) {
          final rel = td.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (rel.length >= 8) {
            work['release'] = '${rel.substring(0, 4)}-${rel.substring(4, 6)}-${rel.substring(6, 8)}';
          }
        } else if (thText == seriesLabel) {
          final seriesA = td.querySelector('a');
          final href = seriesA?.attributes['href'] ?? '';
          final match = RegExp(r'SRI(\d{10})').firstMatch(href);
          if (match != null) {
            work['series'] = {'id': int.parse(match.group(1)!), 'name': seriesA!.text};
          }
        } else if (thText == genreLabel) {
          td.querySelectorAll('div > a').forEach((a) {
            final href = a.attributes['href'] ?? '';
            final match = RegExp(r'genre/(\d{3})').firstMatch(href);
            if (match != null) {
              work['tags'].add({'id': int.parse(match.group(1)!), 'name': a.text});
            }
          });
        } else if (thText == vaLabel) {
          td.querySelectorAll('a').forEach((a) {
            final name = a.text.trim();
            work['vas'].add({'id': ScraperUtils.nameToUUID(name), 'name': name});
          });
        }
      }
    }

    // 声优兜底逻辑
    if ((work['vas'] as List).isEmpty) {
      try {
        final hvdbData = await HvdbScraper.scrapeWorkMetadata(id);
        final hvdbVas = hvdbData['vas'] as List;
        if (hvdbVas.length <= 1) {
          work['vas'] = hvdbVas;
        } else {
          for (var va in hvdbVas) {
            if (!ScraperUtils.hasLetter(va['name'])) {
              work['vas'].add(va);
            }
          }
        }
      } catch (_) {}
    }

    return work;
  }

  static Future<Map<String, dynamic>> scrapeDynamic(int id) async {
    final String rjcode = ScraperUtils.toRjCode(id);
    final String url = 'https://www.dlsite.com/maniax-touch/product/info/ajax?product_id=$rjcode';
    debugPrint('当前JSON请求路径为：$url');
    final response = await DioClient.retryGet(url);
    final data = response.data[rjcode];

    final Map<String, dynamic> work = {
      'mainCoverUrl': 'https://${data['work_image']}',
      'dl_count': data['dl_count'] ?? "0",
      'rate_average_2dp': data['rate_average_2dp'] ?? 0.0,
      'rate_count': data['rate_count'] ?? 0,
      'rate_count_detail': data['rate_count_detail'],
      'review_count': data['review_count'],
      'price': data['price'],
    };

    if (data['rank'] != null && (data['rank'] as List).isNotEmpty) {
      work['rank'] = data['rank'];
    }

    debugPrint('[RJ$rjcode] 成功从 DLSite 抓取 Dynamic 元数据...');
    return work;
  }

  static Future<Map<String, dynamic>> scrapeAll(int id, {String language = 'zh-cn'}) async {
    final results = await Future.wait([
      scrapeStatic(id, language),
      scrapeDynamic(id),
    ]);

    // 合并 Map
    return {...results[0], ...results[1]};
  }
}