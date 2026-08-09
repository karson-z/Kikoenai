import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';

import '../widget/parsed_works_view.dart';
import '../widget/scraper_drawer.dart';

class ParsedWorksPage extends ConsumerWidget {
  const ParsedWorksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(scraperQueueProvider);
    final queueCount = queueState.pending.length + queueState.processing.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        title: const Text(
          'DL库',
          style: TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: '解析队列',
                icon: Badge(
                  isLabelVisible: queueCount > 0,
                  label: Text(queueCount.toString()),
                  child: const Icon(Icons.swap_vert_circle_outlined),
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: const ScraperQueueDrawer(),
      body: ValueListenableBuilder(
        valueListenable: AppStorage.scraperWorkBox.listenable(),
        builder: (context, box, child) {
          return ParseWorksView(work: box.values.toList());
        },
      ),
    );
  }
}
