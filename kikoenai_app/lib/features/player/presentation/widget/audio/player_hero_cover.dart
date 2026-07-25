import 'package:flutter/material.dart';

import '../../../../../core/widgets/image_box/simple_extended_image.dart';

class FloatingCoverImage extends StatelessWidget {
  final String? url;
  final double radiusValue;

  const FloatingCoverImage({super.key, this.url, required this.radiusValue});

  @override
  Widget build(BuildContext context) {
    return SimpleExtendedImage(
      url ?? '',
      borderRadius: BorderRadius.circular(radiusValue),
      fit: BoxFit.cover,
      loadingSize: 20,
    );
  }
}