import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';

import '../widget/dl_library_header.dart';
import '../widget/parsed_works_view.dart';
import '../widget/scraper_drawer.dart';

class ParsedWorksPage extends ConsumerWidget {
  const ParsedWorksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(scraperQueueProvider);
    final queueCount = queueState.pending.length + queueState.processing.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      endDrawer: const ScraperQueueDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Builder(
              builder: (headerContext) => DlLibraryHeader(
                queueCount: queueCount,
                onOpenQueue: () => Scaffold.of(headerContext).openEndDrawer(),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: AppStorage.scraperWorkBox.listenable(),
                builder: (context, box, child) {
                  return ParseWorksView(work: box.values.toList());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
