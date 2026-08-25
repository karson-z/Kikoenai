import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/pagination/kiko_paging_state.dart';

void main() {
  group('KikoPagingState', () {
    test('按页保存数据并计算下一页键', () {
      final firstPage = KikoPagingState<int>().appendPage(
        pageKey: 1,
        pageItems: const [1, 2],
        totalCount: 4,
        filterFingerprint: 'filter-a',
      );

      expect(firstPage.pages, const [
        [1, 2],
      ]);
      expect(firstPage.keys, const [1]);
      expect(firstPage.itemList, const [1, 2]);
      expect(firstPage.nextPageKey, 2);
      expect(firstPage.hasNextPage, isTrue);
      expect(firstPage.totalCount, 4);
      expect(firstPage.filterFingerprint, 'filter-a');

      final secondPage = firstPage.appendPage(
        pageKey: firstPage.nextPageKey,
        pageItems: const [3, 4],
        totalCount: 4,
      );

      expect(secondPage.pages, const [
        [1, 2],
        [3, 4],
      ]);
      expect(secondPage.keys, const [1, 2]);
      expect(secondPage.itemList, const [1, 2, 3, 4]);
      expect(secondPage.hasNextPage, isFalse);
      expect(secondPage.filterFingerprint, 'filter-a');
    });

    test('空页立即结束分页', () {
      final state = KikoPagingState<int>().appendPage(
        pageKey: 1,
        pageItems: const [],
        totalCount: 10,
      );

      expect(state.itemList, isEmpty);
      expect(state.hasNextPage, isFalse);
    });

    test('成功追加页面时清除上一次错误', () {
      final failed = KikoPagingState<int>(
        pages: const [
          [1],
        ],
        keys: const [1],
        error: StateError('network error'),
        totalCount: 2,
      );

      final retried = failed.appendPage(
        pageKey: 2,
        pageItems: const [2],
        totalCount: 2,
      );

      expect(retried.error, isNull);
      expect(retried.itemList, const [1, 2]);
      expect(retried.hasNextPage, isFalse);
    });

    test('reset 恢复库要求的首屏初始状态', () {
      final state = KikoPagingState<int>(
        pages: const [
          [1],
        ],
        keys: const [1],
        hasNextPage: false,
        totalCount: 1,
        filterFingerprint: 'filter-a',
      ).reset();

      expect(state.pages, isNull);
      expect(state.keys, isNull);
      expect(state.hasNextPage, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.totalCount, 0);
      expect(state.filterFingerprint, isEmpty);
    });
  });
}
