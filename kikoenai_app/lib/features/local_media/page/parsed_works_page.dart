import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';

import '../widget/parsed_works_view.dart';

class ParsedWorksPage extends StatelessWidget {
  const ParsedWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        title: const Text(
          'DL库',
          style: TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: AppStorage.scraperWorkBox.listenable(),
        builder: (context, box, child) {
          return ParseWorksView(work: box.values.toList());
        },
      ),
    );
  }
}
