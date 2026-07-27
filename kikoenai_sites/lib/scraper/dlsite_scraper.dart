import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

import 'hvdb_scraper.dart';
import 'scraper_http_client.dart';
import 'scraper_utils.dart';

/// DLSite 爬虫（迁移自 `kikoenai_app/lib/core/utils/scraper/scraper.dart`）。
///
/// 提供静态 HTML 元数据与动态 JSON 元数据的抓取，并支持合并为完整结果。
class DlSiteScraper {
  DlSiteScraper._();

  /// 抓取静态页面元数据（标题、社团、标签、声优等）
  static Future<Map<String, dynamic>> scrapeStatic(
    int id,
    String language,
  ) async {
    final String rjcode = ScraperUtils.toRjCode(id);
    final String url =
        'https://www.dlsite.com/maniax/work/=/product_id/$rjcode.html';
    debugPrint('当前页面请求路径为：$url');

    String ageLabel, genreLabel, vaLabel, releaseLabel, seriesLabel, cookieLocale;
    switch (language) {
      case 'ja-jp':
        cookieLocale = 'locale=ja-jp';
        ageLabel = '年齢指定';
        genreLabel = 'ジャンル';
        vaLabel = '声優';
        releaseLabel = '販売日';
        seriesLabel = 'シリーズ名';
        break;
      case 'zh-tw':
        cookieLocale = 'locale=zh-tw';
        ageLabel = '年齡指定';
        genreLabel = '分類';
        vaLabel = '聲優';
        releaseLabel = '販賣日';
        seriesLabel = '系列名';
        break;
      default:
        cookieLocale = 'locale=zh-cn';
        ageLabel = '年龄指定';
        genreLabel = '分类';
        vaLabel = '声优';
        releaseLabel = '贩卖日';
        seriesLabel = '系列名';
    }

    final response = await ScraperHttpClient.retryGet(
      url,
      headers: {'cookie': cookieLocale},
    );
    final document = parse(response.data);

    final Map<String, dynamic> work = {
      'id': id,
      'rjCode': rjcode,
      'tags': <Map<String, dynamic>>[],
      'vas': <Map<String, dynamic>>[],
    };

    // 标题解析与清洗
    var title =
        document.querySelector('meta[property="og:title"]')?.attributes['content'];
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
            work['release'] =
                '${rel.substring(0, 4)}-${rel.substring(4, 6)}-${rel.substring(6, 8)}';
          }
        } else if (thText == seriesLabel) {
          final seriesA = td.querySelector('a');
          final href = seriesA?.attributes['href'] ?? '';
          final match = RegExp(r'SRI(\d{10})').firstMatch(href);
          if (match != null) {
            work['series'] = {
              'id': int.parse(match.group(1)!),
              'name': seriesA!.text,
            };
          }
        } else if (thText == genreLabel) {
          td.querySelectorAll('div > a').forEach((a) {
            final href = a.attributes['href'] ?? '';
            final match = RegExp(r'genre/(\d{3})').firstMatch(href);
            if (match != null) {
              (work['tags'] as List).add({
                'id': int.parse(match.group(1)!),
                'name': a.text,
              });
            }
          });
        } else if (thText == vaLabel) {
          td.querySelectorAll('a').forEach((a) {
            final name = a.text.trim();
            (work['vas'] as List).add({
              'id': ScraperUtils.nameToUUID(name),
              'name': name,
            });
          });
        }
      }
    }

    // 声优兜底：DLSite 解析为空时尝试 HVDB
    if ((work['vas'] as List).isEmpty) {
      try {
        final hvdbData = await HvdbScraper.scrapeWorkMetadata(id);
        final hvdbVas = hvdbData['vas'] as List;
        if (hvdbVas.length <= 1) {
          work['vas'] = hvdbVas;
        } else {
          for (var va in hvdbVas) {
            final name = va['name'] as String;
            if (!ScraperUtils.hasLetter(name)) {
              (work['vas'] as List).add(va);
            }
          }
        }
      } catch (_) {}
    }

    return work;
  }

  /// 抓取动态 JSON 元数据（封面、评分、销量、价格等）
  static Future<Map<String, dynamic>> scrapeDynamic(int id) async {
    final String rjcode = ScraperUtils.toRjCode(id);
    final String url =
        'https://www.dlsite.com/maniax-touch/product/info/ajax?product_id=$rjcode';
    debugPrint('当前JSON请求路径为：$url');

    final response = await ScraperHttpClient.retryGet(url);
    final data = response.data[rjcode];

    final Map<String, dynamic> work = {
      'mainCoverUrl': 'https:${data['work_image']}',
      'dl_count': data['dl_count'] ?? '0',
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

  /// 合并抓取静态 + 动态元数据
  static Future<Map<String, dynamic>> scrapeAll(
    int id, {
    String language = 'zh-cn',
  }) async {
    final results = await Future.wait([
      scrapeStatic(id, language),
      scrapeDynamic(id),
    ]);
    return {...results[0], ...results[1]};
  }
}
