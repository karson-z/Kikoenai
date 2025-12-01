import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumCategory extends ConsumerWidget {
  const AlbumCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('标题'),
      ),
      body: Center(
        child: Text('内容区域'),
      ),
    );
  }
}
