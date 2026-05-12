import 'package:flutter/cupertino.dart';
import 'package:kikoenai/core/model/file_node.dart';

import '../../../features/album/data/model/work.dart';

class HistoryWorkCard extends StatelessWidget {
  final Work? work; // 作品集
  final FileNode? singleWork; // 单作品（本地视频、零散音频）


  const HistoryWorkCard({super.key, this.work, this.singleWork});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}