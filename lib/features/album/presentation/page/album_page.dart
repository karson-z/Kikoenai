import 'package:flutter/material.dart';
import 'package:name_app/features/album/data/model/product_mock.dart';
import 'package:name_app/features/album/presentation/widget/work_card.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ResponsiveCardGrid(products: mockProducts),
    );
  }
}
