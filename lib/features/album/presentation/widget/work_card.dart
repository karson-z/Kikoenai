import 'package:flutter/material.dart';
import 'package:name_app/features/album/data/model/product_mock.dart';
import 'package:name_app/features/album/presentation/widget/work_tag.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final computedTitleFontSize = cardWidth / 15;
          final computedCircleFontSize = cardWidth / 20;
          // 根据卡片宽高动态计算标签尺寸
          double computeFontSize() => cardWidth / 20;
          double computePadding() => cardWidth / 30;
          return Column(
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
                          : const Center(
                          child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child:
                        const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child:
                      _buildBadge(product.id, Colors.black.withAlpha(60)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildBadge('全年龄', Colors.green.withAlpha(128)),
                    ),
                  ],
                )),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: computedTitleFontSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.circle,
                      style: TextStyle(
                          fontSize: computedCircleFontSize,
                          color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    TagRow(
                      tags: product.authors,
                      type: TagType.author,
                      fontSize: computeFontSize(),
                      borderRadius: 8,
                      padding: EdgeInsets.all(computePadding()),
                    ),
                    const SizedBox(height: 4),
                    TagRow(
                      tags: product.tags,
                      type: TagType.normal,
                      fontSize: computeFontSize(),
                      borderRadius: 25,
                      padding: EdgeInsets.all(computePadding()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
