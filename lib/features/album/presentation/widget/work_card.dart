import 'package:flutter/material.dart';
import 'package:name_app/features/album/data/model/product_mock.dart';

// --- 简单的布局策略 ---
class WorkLayoutStrategy {
  const WorkLayoutStrategy();

  int getColumnsCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  double getColumnSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 16;
    if (width >= 800) return 12;
    return 8;
  }

  EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return const EdgeInsets.all(16);
    if (width >= 800) return const EdgeInsets.all(12);
    return const EdgeInsets.all(8);
  }
}

// --- 响应式网格 ---
class ResponsiveCardGrid extends StatelessWidget {
  final List<Product> products;

  const ResponsiveCardGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final layoutStrategy = WorkLayoutStrategy();
    final columns = layoutStrategy.getColumnsCount(context);
    final spacing = layoutStrategy.getColumnSpacing(context);
    final padding = layoutStrategy.getPadding(context);

    return GridView.builder(
      padding: padding,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}

// --- 单个卡片 ---
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildBadge(product.id, Colors.black.withOpacity(0.6)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildBadge('全年龄', Colors.green.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.circle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildTagRow(product.authors, author: true),
                const SizedBox(height: 4),
                _buildTagRow(product.tags),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTagRow(List<String> tags, {bool author = false}) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 28,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tags
              .map(
                (tag) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    avatar: author ? const Icon(Icons.person, size: 14) : null,
                    label: Text(tag),
                    labelPadding: author
                        ? const EdgeInsets.only(left: 4, right: 8)
                        : const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
