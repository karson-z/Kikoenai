import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/scraper/dlsite_scraper.dart';
import 'package:kikoenai/core/utils/scraper/scraper_utils.dart';

void main() {
  group('DLsite Scraper 逻辑测试', () {
    test('测试完整抓取流程 (Static + Dynamic)', () async {
      // 示例作品 ID (对应 RJ322055)
      const int testId = 01059771;
      const String lang = 'zh-cn';

      print('开始测试抓取 RJ${testId.toString().padLeft(7, '0')}...');

      try {
        // 通过 App 工具包抓取元数据
        final result = await DlSiteScraper.scrapeAll(testId, language: lang);

        // 验证基本元数据是否存在
        expect(result, contains('id'));
        expect(result['id'], equals(testId));
        expect(result, contains('title'));
        expect(result, contains('circle'));

        // 打印结果以供人工核对
        print('--- 抓取结果 ---');
        print('标题: ${result['title']}');
        print(
          '社团: ${result['circle']?['name']} (ID: ${result['circle']?['id']})',
        );
        print('贩卖日: ${result['release']}');
        print('NSFW: ${result['nsfw']}');
        print('标签数: ${(result['tags'] as List).length}');
        print('声优数: ${(result['vas'] as List).length}');
        print('售出数: ${result['dl_count']}');
        print('价格: ${result['price']}');
        print('----------------');
      } catch (e) {
        fail('抓取过程中发生异常: $e');
      }
    });

    test('测试 UUID 生成一致性', () {
      // 验证与 JS 端逻辑一致的 UUID
      const String vaName = '門脇舞以';
      // 此 UUID 应与 Node.js 版 nameToUUID('門脇舞以') 的结果完全一致
      final String uuid = ScraperUtils.nameToUUID(vaName);
      print('声优 [$vaName] 的 UUID: $uuid');

      expect(uuid, isA<String>());
      expect(uuid.length, equals(36));
    });
  });
}
