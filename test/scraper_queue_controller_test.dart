import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/core/utils/scraper/scraper_http_client.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _node(int id) {
  return FileNode(
    type: NodeType.folder,
    title: 'RJ$id',
    hash: 'task-$id',
    workId: id,
    nodeStatus: NodeStatus.pending,
  );
}

ProviderContainer _container(ScraperWorkLoader loader) {
  return ProviderContainer(
    overrides: [
      scraperWorkLoaderProvider.overrideWithValue(loader),
      scraperWorkExistsProvider.overrideWithValue((_) => false),
      scraperWorkSaverProvider.overrideWithValue((_, _) async {}),
      scraperStatusUpdaterProvider.overrideWithValue((_, _) async {}),
      scraperQueueDelayProvider.overrideWithValue(Duration.zero),
      scraperQueueConcurrencyProvider.overrideWithValue(1),
    ],
  );
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for scraper queue state');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  test(
    'pauses an active task immediately and resumes it to completion',
    () async {
      final firstAttemptStarted = Completer<ScraperCancellationToken>();
      var attempts = 0;
      final container = _container((workId, cancellationToken) async {
        attempts++;
        if (attempts == 1) {
          firstAttemptStarted.complete(cancellationToken);
          await cancellationToken.whenCancelled;
          cancellationToken.throwIfCancelled();
        }
        return Work(id: workId);
      });
      addTearDown(container.dispose);

      final notifier = container.read(scraperQueueProvider.notifier);
      final node = _node(101);
      await notifier.addTasks([node]);
      notifier.start();

      final firstToken = await firstAttemptStarted.future;
      notifier.pauseTask(node.keyId);

      var state = container.read(scraperQueueProvider);
      expect(firstToken.isCancelled, isTrue);
      expect(state.processing, isEmpty);
      expect(state.paused.map((item) => item.keyId), [node.keyId]);
      expect(state.isRunning, isFalse);

      notifier.resumeTask(node.keyId);
      await _waitUntil(
        () => container.read(scraperQueueProvider).completed.length == 1,
      );

      state = container.read(scraperQueueProvider);
      expect(attempts, 2);
      expect(state.pending, isEmpty);
      expect(state.processing, isEmpty);
      expect(state.paused, isEmpty);
      expect(state.completed.single.keyId, node.keyId);
      expect(state.isRunning, isFalse);
    },
  );

  test(
    'pause all cancels active work and start completes every task',
    () async {
      final activeAttemptStarted = Completer<ScraperCancellationToken>();
      final attempts = <int, int>{};
      final container = _container((workId, cancellationToken) async {
        attempts.update(workId, (count) => count + 1, ifAbsent: () => 1);
        if (workId == 201 && attempts[workId] == 1) {
          activeAttemptStarted.complete(cancellationToken);
          await cancellationToken.whenCancelled;
          cancellationToken.throwIfCancelled();
        }
        return Work(id: workId);
      });
      addTearDown(container.dispose);

      final notifier = container.read(scraperQueueProvider.notifier);
      final nodes = [_node(201), _node(202), _node(203)];
      await notifier.addTasks(nodes);
      notifier.start();

      final activeToken = await activeAttemptStarted.future;
      notifier.pauseAll();

      var state = container.read(scraperQueueProvider);
      expect(activeToken.isCancelled, isTrue);
      expect(state.pending, isEmpty);
      expect(state.processing, isEmpty);
      expect(state.paused.map((item) => item.keyId).toSet(), {
        for (final node in nodes) node.keyId,
      });
      expect(state.isRunning, isFalse);

      notifier.start();
      await _waitUntil(
        () =>
            container.read(scraperQueueProvider).completed.length ==
            nodes.length,
      );

      state = container.read(scraperQueueProvider);
      expect(attempts, {201: 2, 202: 1, 203: 1});
      expect(state.pending, isEmpty);
      expect(state.processing, isEmpty);
      expect(state.paused, isEmpty);
      expect(state.completed.length, nodes.length);
      expect(state.isRunning, isFalse);
    },
  );

  test('clear queue after pause does not restore an exiting task', () async {
    final activeAttemptStarted = Completer<ScraperCancellationToken>();
    final cancellationObserved = Completer<void>();
    final container = _container((workId, cancellationToken) async {
      activeAttemptStarted.complete(cancellationToken);
      await cancellationToken.whenCancelled;
      cancellationObserved.complete();
      cancellationToken.throwIfCancelled();
      return Work(id: workId);
    });
    addTearDown(container.dispose);

    final notifier = container.read(scraperQueueProvider.notifier);
    await notifier.addTasks([_node(301)]);
    notifier.start();
    await activeAttemptStarted.future;

    notifier.pauseAll();
    notifier.clearQueue();
    await cancellationObserved.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(scraperQueueProvider);
    expect(state.pending, isEmpty);
    expect(state.processing, isEmpty);
    expect(state.paused, isEmpty);
    expect(state.completed, isEmpty);
    expect(state.failed, isEmpty);
    expect(state.isRunning, isFalse);
  });
}
