import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/audio/shuffle_queue_order.dart';

void main() {
  group('ShuffleQueueOrder', () {
    test('plays each item once per round and previous follows the cursor', () {
      final order = ShuffleQueueOrder(random: Random(1));
      const queue = ['a', 'b', 'c', 'd'];
      order.reset(queue, currentId: 'a');

      final firstRound = [
        for (var i = 0; i < 3; i++) order.next(queueIds: queue, repeat: false)!,
      ];
      expect(['a', ...firstRound].toSet(), queue.toSet());
      expect(order.next(queueIds: queue, repeat: false), isNull);

      final previous = firstRound[firstRound.length - 2];
      final last = firstRound.last;
      expect(order.previous(), previous);
      expect(order.next(queueIds: queue, repeat: false), last);
    });

    test(
      'repeating starts a new shuffled round without immediate repetition',
      () {
        for (var seed = 0; seed < 50; seed++) {
          final order = ShuffleQueueOrder(random: Random(seed));
          const queue = ['a', 'b', 'c', 'd'];
          order.reset(queue, currentId: 'a');
          for (var i = 0; i < 3; i++) {
            order.next(queueIds: queue, repeat: true);
          }
          final last = order.items[order.cursor];
          final next = order.next(queueIds: queue, repeat: true);
          expect(next, isNot(last), reason: 'seed $seed');
        }
      },
    );

    test(
      'direct selection preserves previous navigation and reshuffles future',
      () {
        final order = ShuffleQueueOrder(random: Random(2));
        const queue = ['a', 'b', 'c', 'd'];
        order.reset(queue, currentId: 'a');
        final previous = order.next(queueIds: queue, repeat: true)!;
        order.select('d', queue);

        expect(order.previous(), previous);
        expect(order.next(queueIds: queue, repeat: true), 'd');
        expect(order.previous(), previous);
      },
    );

    test(
      'manual selection does not replay tracks already played this round',
      () {
        final order = ShuffleQueueOrder(random: Random(12));
        const queue = ['a', 'b', 'c', 'd', 'e'];
        order.reset(queue, currentId: 'a');
        final alreadyPlayed = order.next(queueIds: queue, repeat: true)!;
        order.select('e', queue);

        final pending = <String>[];
        while (order.hasNext) {
          pending.add(order.next(queueIds: queue, repeat: false)!);
        }
        expect(pending, isNot(contains('a')));
        expect(pending, isNot(contains(alreadyPlayed)));
        expect(pending.toSet(), {'b', 'c', 'd'});
      },
    );

    test('queue additions and removals update only the pending sequence', () {
      final order = ShuffleQueueOrder(random: Random(3));
      order.reset(['a', 'b', 'c'], currentId: 'a');
      order.addPending(['d']);
      order.remove('b');
      final pending = <String>[];
      for (var i = 0; i < 3; i++) {
        final id = order.next(queueIds: ['a', 'c', 'd'], repeat: false);
        if (id != null) pending.add(id);
      }
      expect(pending.toSet(), {'c', 'd'});
      expect(pending, hasLength(2));
    });

    test(
      'snapshot restores the same sequence and rejects a different queue',
      () {
        final original = ShuffleQueueOrder(random: Random(4));
        const queue = ['a', 'b', 'c', 'd'];
        original.reset(queue, currentId: 'a');
        original.next(queueIds: queue, repeat: true);
        final snapshot = original.toSnapshot(queue);
        final expected = original.next(queueIds: queue, repeat: true);

        final restored = ShuffleQueueOrder(random: Random(9));
        restored.reset(
          queue,
          currentId: snapshot['items'] is List
              ? (snapshot['items'] as List)[snapshot['cursor'] as int] as String
              : null,
          snapshot: snapshot,
        );
        expect(restored.next(queueIds: queue, repeat: true), expected);

        final stale = ShuffleQueueOrder(random: Random(10));
        stale.reset(['x', 'y'], currentId: 'x', snapshot: snapshot);
        expect(stale.items.toSet(), {'x', 'y'});
      },
    );

    test('empty and single-item queues stay in range', () {
      final order = ShuffleQueueOrder();
      order.reset([], currentId: null);
      expect(order.next(queueIds: [], repeat: true), isNull);
      expect(order.previous(), isNull);
      order.reset(['a'], currentId: 'a');
      expect(order.next(queueIds: ['a'], repeat: true), 'a');
      expect(order.previous(), 'a');
    });
  });
}
