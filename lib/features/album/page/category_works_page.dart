import 'package:flutter/material.dart';
import 'package:kikoenai/features/album/widget/smart_works_sliver_grid.dart';

class CategoryWorksPage extends StatelessWidget {
  final String title;
  final WorkDataSource source;

  const CategoryWorksPage({
    super.key,
    required this.title,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // 直接使用 CustomScrollView 配合你的智能容器
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          SmartWorksSliverGrid(source: source),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}