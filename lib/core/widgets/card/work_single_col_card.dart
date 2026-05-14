import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';

import '../../../features/album/data/model/work.dart';
import '../../../features/album/presentation/widget/work_tag.dart';
import '../../enums/tag_enum.dart';
import '../../routes/app_routes.dart';

class WorkSingleColCard extends StatelessWidget{
  final Work work;

  const WorkSingleColCard({super.key,required this.work});
  @override
  Widget build(BuildContext context) {
     return GestureDetector(
       onTap: () {
       context.push(AppRoutes.detail, extra: {'work': work,'isLocal': false});
     },
       child: Container(
         padding: const EdgeInsets.all(12),
         child: Row(
           children: [
             SimpleExtendedImage(
                 height: 72,
                 width: 72,
                 work.mainCoverUrl ?? ''
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(work.title ?? '',style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 13,),maxLines: 1,),
                   const SizedBox(height: 4),
                   TagRow(tags: work.vas ?? [], type: TagType.va),
                   const SizedBox(height: 4),
                   TagRow(tags: work.tags ?? [], type: TagType.tag),
                 ],
               ),
             )
           ],
         ),
       ),
     );
  }

}